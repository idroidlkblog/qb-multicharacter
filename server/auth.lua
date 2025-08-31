local QBCore = exports['qb-core']:GetCoreObject()

-- Database setup
CreateThread(function()
    MySQL.query([[
        CREATE TABLE IF NOT EXISTS user_accounts (
            id INT AUTO_INCREMENT PRIMARY KEY,
            username VARCHAR(50) UNIQUE NOT NULL,
            email VARCHAR(100) UNIQUE NOT NULL,
            password_hash VARCHAR(255) NOT NULL,
            license VARCHAR(100) UNIQUE NOT NULL,
            created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
            last_login TIMESTAMP NULL,
            is_active BOOLEAN DEFAULT TRUE,
            INDEX idx_username (username),
            INDEX idx_email (email),
            INDEX idx_license (license)
        )
    ]])
end)

-- Helper Functions
local function IsValidEmail(email)
    local pattern = "^[%w%._%+%-]+@[%w%._%+%-]+%.%w+$"
    return string.match(email, pattern) ~= nil
end

local function IsValidUsername(username)
    if not username or #username < 3 or #username > 20 then
        return false
    end
    local pattern = "^[%w_]+$"
    return string.match(username, pattern) ~= nil
end

local function GetUserByEmail(email)
    local result = MySQL.query.await('SELECT * FROM user_accounts WHERE email = ? AND is_active = TRUE', {email})
    return result[1]
end

local function GetUserByUsername(username)
    local result = MySQL.query.await('SELECT * FROM user_accounts WHERE username = ? AND is_active = TRUE', {username})
    return result[1]
end

local function GetUserByLicense(license)
    local result = MySQL.query.await('SELECT * FROM user_accounts WHERE license = ? AND is_active = TRUE', {license})
    return result[1]
end

local function CreateUserAccount(username, email, passwordHash, license)
    local result = MySQL.insert.await([[
        INSERT INTO user_accounts (username, email, password_hash, license) 
        VALUES (?, ?, ?, ?)
    ]], {username, email, passwordHash, license})
    return result
end

local function UpdateLastLogin(userId)
    MySQL.update('UPDATE user_accounts SET last_login = NOW() WHERE id = ?', {userId})
end

-- Events
RegisterNetEvent('qb-multicharacter:server:attemptLogin', function(email, password)
    local src = source
    local license = QBCore.Functions.GetIdentifier(src, 'license')
    
    if not license then
        TriggerClientEvent('qb-multicharacter:client:loginResult', src, {
            success = false,
            message = 'Unable to verify your identity. Please restart FiveM.'
        })
        return
    end

    if not email or not password or email == '' or password == '' then
        TriggerClientEvent('qb-multicharacter:client:loginResult', src, {
            success = false,
            message = 'Please fill in all fields.'
        })
        return
    end

    if not IsValidEmail(email) then
        TriggerClientEvent('qb-multicharacter:client:loginResult', src, {
            success = false,
            message = 'Please enter a valid email address.'
        })
        return
    end

    local user = GetUserByEmail(email)
    if not user then
        TriggerClientEvent('qb-multicharacter:client:loginResult', src, {
            success = false,
            message = 'Invalid email or password.'
        })
        return
    end

    local valid = exports['fivem-bcrypt-async']:VerifyPasswordHash(password, user.password_hash)
    if valid then
        if user.license ~= license then
            TriggerClientEvent('qb-multicharacter:client:loginResult', src, {
                success = false,
                message = 'This account is linked to a different FiveM license.'
            })
            return
        end

        UpdateLastLogin(user.id)
        TriggerClientEvent('qb-multicharacter:client:loginResult', src, {
            success = true,
            message = 'Login successful!',
            userData = {
                id = user.id,
                username = user.username,
                email = user.email
            }
        })
    else
        TriggerClientEvent('qb-multicharacter:client:loginResult', src, {
            success = false,
            message = 'Invalid email or password.'
        })
    end
end)

RegisterNetEvent('qb-multicharacter:server:attemptRegister', function(username, email, password)
    local src = source
    local license = QBCore.Functions.GetIdentifier(src, 'license')

    if not license then
        TriggerClientEvent('qb-multicharacter:client:registerResult', src, {
            success = false,
            message = 'Unable to verify your identity. Please restart FiveM.'
        })
        return
    end

    if not username or not email or not password or username == '' or email == '' or password == '' then
        TriggerClientEvent('qb-multicharacter:client:registerResult', src, {
            success = false,
            message = 'Please fill in all fields.'
        })
        return
    end

    if not IsValidUsername(username) then
        TriggerClientEvent('qb-multicharacter:client:registerResult', src, {
            success = false,
            message = 'Username must be 3-20 characters and contain only letters, numbers, and underscores.'
        })
        return
    end

    if not IsValidEmail(email) then
        TriggerClientEvent('qb-multicharacter:client:registerResult', src, {
            success = false,
            message = 'Please enter a valid email address.'
        })
        return
    end

    if #password < 6 then
        TriggerClientEvent('qb-multicharacter:client:registerResult', src, {
            success = false,
            message = 'Password must be at least 6 characters long.'
        })
        return
    end

    if GetUserByEmail(email) then
        TriggerClientEvent('qb-multicharacter:client:registerResult', src, {
            success = false,
            message = 'An account with this email already exists.'
        })
        return
    end

    if GetUserByUsername(username) then
        TriggerClientEvent('qb-multicharacter:client:registerResult', src, {
            success = false,
            message = 'This username is already taken.'
        })
        return
    end

    if GetUserByLicense(license) then
        TriggerClientEvent('qb-multicharacter:client:registerResult', src, {
            success = false,
            message = 'Your FiveM license is already linked to another account.'
        })
        return
    end

    local hash = exports['fivem-bcrypt-async']:GetPasswordHash(password)
    local userId = CreateUserAccount(username, email, hash, license)
    if userId then
        TriggerClientEvent('qb-multicharacter:client:registerResult', src, {
            success = true,
            message = 'Account created successfully! You can now sign in.'
        })
        print('^2[qb-multicharacter]^7 New account registered: ' .. username .. ' (' .. email .. ')')
    else
        TriggerClientEvent('qb-multicharacter:client:registerResult', src, {
            success = false,
            message = 'Failed to create account. Please try again.'
        })
    end
end)

-- Callbacks
QBCore.Functions.CreateCallback('qb-multicharacter:server:getUserAccount', function(source, cb)
    local src = source
    local license = QBCore.Functions.GetIdentifier(src, 'license')
    if license then
        cb(GetUserByLicense(license))
    else
        cb(nil)
    end
end)

-- Admin Commands
QBCore.Commands.Add('resetuseraccount', 'Reset a user account (Admin Only)', {
    {name = 'email', help = 'Email address of the account to reset'}
}, true, function(source, args)
    local email = args[1]
    if not email then
        TriggerClientEvent('QBCore:Notify', source, 'Please provide an email address.', 'error')
        return
    end

    local user = GetUserByEmail(email)
    if not user then
        TriggerClientEvent('QBCore:Notify', source, 'No account found with that email.', 'error')
        return
    end

    MySQL.update('UPDATE user_accounts SET is_active = FALSE WHERE email = ?', {email})
    TriggerClientEvent('QBCore:Notify', source, 'Account has been deactivated: ' .. email, 'success')
    print('^3[qb-multicharacter]^7 Admin ' .. GetPlayerName(source) .. ' deactivated account: ' .. email)
end, 'admin')

-- Exports
exports('GetUserByLicense', GetUserByLicense)
exports('GetUserByEmail', GetUserByEmail)
exports('GetUserByUsername', GetUserByUsername)
