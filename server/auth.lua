local QBCore = exports['qb-core']:GetCoreObject()
local bcrypt = exports['fivem-bcrypt-async']

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
    -- Only allow alphanumeric characters and underscores
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

    -- Validate input
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

    -- Get user from database
    local user = GetUserByEmail(email)
    if not user then
        TriggerClientEvent('qb-multicharacter:client:loginResult', src, {
            success = false,
            message = 'Invalid email or password.'
        })
        return
    end

    -- Verify password
    bcrypt.verify(password, user.password_hash, function(result)
        if result then
            -- Check if license matches
            if user.license ~= license then
                TriggerClientEvent('qb-multicharacter:client:loginResult', src, {
                    success = false,
                    message = 'This account is linked to a different FiveM license.'
                })
                return
            end

            -- Update last login
            UpdateLastLogin(user.id)
            
            -- Success - proceed to character selection
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

    -- Validate input
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

    -- Check if user already exists
    local existingUserByEmail = GetUserByEmail(email)
    if existingUserByEmail then
        TriggerClientEvent('qb-multicharacter:client:registerResult', src, {
            success = false,
            message = 'An account with this email already exists.'
        })
        return
    end

    local existingUserByUsername = GetUserByUsername(username)
    if existingUserByUsername then
        TriggerClientEvent('qb-multicharacter:client:registerResult', src, {
            success = false,
            message = 'This username is already taken.'
        })
        return
    end

    local existingUserByLicense = GetUserByLicense(license)
    if existingUserByLicense then
        TriggerClientEvent('qb-multicharacter:client:registerResult', src, {
            success = false,
            message = 'Your FiveM license is already linked to another account.'
        })
        return
    end

    -- Hash password and create account
    bcrypt.hash(password, 12, function(hash)
        if hash then
            local userId = CreateUserAccount(username, email, hash, license)
            if userId then
                TriggerClientEvent('qb-multicharacter:client:registerResult', src, {
                    success = true,
                    message = 'Account created successfully! You can now sign in.'
                })
                
                -- Log the registration
                print('^2[qb-multicharacter]^7 New account registered: ' .. username .. ' (' .. email .. ')')
            else
                TriggerClientEvent('qb-multicharacter:client:registerResult', src, {
                    success = false,
                    message = 'Failed to create account. Please try again.'
                })
            end
        else
            TriggerClientEvent('qb-multicharacter:client:registerResult', src, {
                success = false,
                message = 'Failed to secure your password. Please try again.'
            })
        end
    end)
end)

-- Callbacks
QBCore.Functions.CreateCallback('qb-multicharacter:server:getUserAccount', function(source, cb)
    local src = source
    local license = QBCore.Functions.GetIdentifier(src, 'license')
    
    if license then
        local user = GetUserByLicense(license)
        cb(user)
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

-- Export functions for other resources
exports('GetUserByLicense', GetUserByLicense)
exports('GetUserByEmail', GetUserByEmail)
exports('GetUserByUsername', GetUserByUsername)