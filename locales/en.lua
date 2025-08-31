local Translations = {
    notifications = {
        ["char_deleted"] = "Character deleted!",
        ["deleted_other_char"] = "You successfully deleted the character with citizen id %{citizenid}.",
        ["forgot_citizenid"] = "You forgot to input a citizen id!",
    },

    commands = {
        -- /deletechar
        ["deletechar_description"] = "Deletes another players character",
        ["citizenid"] = "Citizen ID",
        ["citizenid_help"] = "The Citizen ID of the character you want to delete",

        -- /logout
        ["logout_description"] = "Logout of Character (Admin Only)",

        -- /closeNUI
        ["closeNUI_description"] = "Close Multi NUI"
    },

    misc = {
        ["droppedplayer"] = "You have disconnected from QBCore"
    },

    ui = {
        -- Main
        characters_header = "My Characters",
        emptyslot = "Empty Slot",
        play_button = "Play",
        create_button = "Create Character",
        delete_button = "Delete Character",

        -- Character Information
        charinfo_header = "Character Information",
        charinfo_description = "Select a character slot to see all information about your character.",
        name = "Name",
        male = "Male",
        female = "Female",
        firstname = "First Name",
        lastname = "Last Name",
        nationality = "Nationality",
        gender = "Gender",
        birthdate = "Birthdate",
        job = "Job",
        jobgrade = "Job Grade",
        cash = "Cash",
        bank = "Bank",
        phonenumber = "Phone Number",
        accountnumber = "Account Number",

        chardel_header = "Character Registration",

        -- Delete character
        deletechar_header = "Delete Character",
        deletechar_description = "Are You Sure You Want To Delete Your Character?",

        -- Buttons
        cancel = "Cancel",
        confirm = "Confirm",

        -- Loading Text
        retrieving_playerdata = "Retrieving player data",
        validating_playerdata = "Validating player data",
        retrieving_characters = "Retrieving characters",
        validating_characters = "Validating characters",

        -- Notifications
        ran_into_issue = "We ran into an issue",
        profanity = "It seems like you are trying to use some type of profanity / bad words in your name or nationality!",
        forgotten_field = "It seems like you have forgotten to input one or multiple of the fields!",

        -- Authentication
        login_header = "Welcome Back",
        login_description = "Sign in to access your characters",
        register_header = "Create Account", 
        register_description = "Join our community today",
        username = "Username",
        email = "Email Address",
        password = "Password",
        confirm_password = "Confirm Password",
        sign_in = "Sign In",
        create_account = "Create Account",
        have_account = "Already have an account?",
        need_account = "Don't have an account?",
        password_requirements = "Password Requirements",
        password_length = "At least 6 characters long",
        password_unique = "Use a unique password",
        login_success = "Login successful! Loading characters...",
        register_success = "Account created successfully! You can now sign in.",
        invalid_credentials = "Invalid email or password.",
        email_exists = "An account with this email already exists.",
        username_taken = "This username is already taken.",
        license_linked = "Your FiveM license is already linked to another account.",
        fill_all_fields = "Please fill in all fields.",
        invalid_email = "Please enter a valid email address.",
        password_too_short = "Password must be at least 6 characters long.",
        passwords_no_match = "Passwords do not match.",
        username_invalid = "Username must be 3-20 characters and contain only letters, numbers, and underscores.",
        connection_error = "Connection error. Please try again.",
        auth_required = "You must be logged in to access characters."
    }
}

Lang = Lang or Locale:new({
    phrases = Translations,
    warnOnMissing = true
})
