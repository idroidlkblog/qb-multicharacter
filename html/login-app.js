class LoginApp {
    constructor() {
        this.currentForm = 'login';
        this.isLoading = false;
        this.init();
    }

    init() {
        this.bindEvents();
        this.setupPasswordToggles();
    }

    bindEvents() {
        // Form switching
        document.getElementById('show-register').addEventListener('click', () => {
            this.switchForm('register');
        });

        document.getElementById('show-login').addEventListener('click', () => {
            this.switchForm('login');
        });

        // Form submissions
        document.getElementById('login-form-element').addEventListener('submit', (e) => {
            e.preventDefault();
            this.handleLogin();
        });

        document.getElementById('register-form-element').addEventListener('submit', (e) => {
            e.preventDefault();
            this.handleRegister();
        });

        // Real-time validation
        document.getElementById('register-confirm-password').addEventListener('input', () => {
            this.validatePasswordMatch();
        });

        document.getElementById('register-password').addEventListener('input', () => {
            this.validatePasswordMatch();
        });
    }

    setupPasswordToggles() {
        const toggleButtons = ['toggle-login-password', 'toggle-register-password'];
        
        toggleButtons.forEach(buttonId => {
            const button = document.getElementById(buttonId);
            const input = button.closest('.relative').querySelector('input');
            
            button.addEventListener('click', () => {
                const isPassword = input.type === 'password';
                input.type = isPassword ? 'text' : 'password';
                button.querySelector('.material-symbols-outlined').textContent = 
                    isPassword ? 'visibility_off' : 'visibility';
            });
        });
    }

    switchForm(formType) {
        const loginForm = document.getElementById('login-form');
        const registerForm = document.getElementById('register-form');

        if (formType === 'register') {
            loginForm.classList.add('hidden');
            registerForm.classList.remove('hidden');
            this.currentForm = 'register';
        } else {
            registerForm.classList.add('hidden');
            loginForm.classList.remove('hidden');
            this.currentForm = 'login';
        }

        // Clear forms
        this.clearForms();
    }

    clearForms() {
        document.getElementById('login-form-element').reset();
        document.getElementById('register-form-element').reset();
        this.clearValidationStates();
    }

    clearValidationStates() {
        const inputs = document.querySelectorAll('input');
        inputs.forEach(input => {
            input.classList.remove('input-error', 'input-success');
        });
    }

    validatePasswordMatch() {
        const password = document.getElementById('register-password').value;
        const confirmPassword = document.getElementById('register-confirm-password').value;
        const confirmInput = document.getElementById('register-confirm-password');

        if (confirmPassword.length > 0) {
            if (password === confirmPassword) {
                confirmInput.classList.remove('input-error');
                confirmInput.classList.add('input-success');
            } else {
                confirmInput.classList.remove('input-success');
                confirmInput.classList.add('input-error');
            }
        } else {
            confirmInput.classList.remove('input-error', 'input-success');
        }
    }

    async handleLogin() {
        if (this.isLoading) return;

        const email = document.getElementById('login-email').value.trim();
        const password = document.getElementById('login-password').value;

        if (!this.validateLoginForm(email, password)) {
            return;
        }

        this.setLoading(true);

        try {
            const response = await this.makeRequest('qb-multicharacter/login', {
                email: email,
                password: password
            });

            if (response.success) {
                this.showToast('Login successful! Loading characters...', 'success');
                setTimeout(() => {
                    this.hideLoginUI();
                }, 1000);
            } else {
                this.showToast(response.message || 'Login failed. Please check your credentials.', 'error');
            }
        } catch (error) {
            this.showToast('Connection error. Please try again.', 'error');
        } finally {
            this.setLoading(false);
        }
    }

    async handleRegister() {
        if (this.isLoading) return;

        const username = document.getElementById('register-username').value.trim();
        const email = document.getElementById('register-email').value.trim();
        const password = document.getElementById('register-password').value;
        const confirmPassword = document.getElementById('register-confirm-password').value;

        if (!this.validateRegisterForm(username, email, password, confirmPassword)) {
            return;
        }

        this.setLoading(true);

        try {
            const response = await this.makeRequest('qb-multicharacter/register', {
                username: username,
                email: email,
                password: password
            });

            if (response.success) {
                this.showToast('Account created successfully! You can now sign in.', 'success');
                setTimeout(() => {
                    this.switchForm('login');
                    document.getElementById('login-email').value = email;
                }, 1500);
            } else {
                this.showToast(response.message || 'Registration failed. Please try again.', 'error');
            }
        } catch (error) {
            this.showToast('Connection error. Please try again.', 'error');
        } finally {
            this.setLoading(false);
        }
    }

    validateLoginForm(email, password) {
        if (!email || !password) {
            this.showToast('Please fill in all fields.', 'warning');
            return false;
        }

        if (!this.isValidEmail(email)) {
            this.showToast('Please enter a valid email address.', 'warning');
            return false;
        }

        return true;
    }

    validateRegisterForm(username, email, password, confirmPassword) {
        if (!username || !email || !password || !confirmPassword) {
            this.showToast('Please fill in all fields.', 'warning');
            return false;
        }

        if (username.length < 3 || username.length > 20) {
            this.showToast('Username must be between 3 and 20 characters.', 'warning');
            return false;
        }

        if (!this.isValidEmail(email)) {
            this.showToast('Please enter a valid email address.', 'warning');
            return false;
        }

        if (password.length < 6) {
            this.showToast('Password must be at least 6 characters long.', 'warning');
            return false;
        }

        if (password !== confirmPassword) {
            this.showToast('Passwords do not match.', 'warning');
            return false;
        }

        return true;
    }

    isValidEmail(email) {
        const emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
        return emailRegex.test(email);
    }

    async makeRequest(endpoint, data) {
        const response = await axios.post(`https://${endpoint}`, data);
        return response.data;
    }

    setLoading(loading) {
        this.isLoading = loading;
        const overlay = document.getElementById('loading-overlay');
        
        if (loading) {
            overlay.classList.remove('hidden');
        } else {
            overlay.classList.add('hidden');
        }
    }

    hideLoginUI() {
        document.getElementById('login-app').style.display = 'none';
    }

    showToast(message, type = 'info') {
        // Remove existing toasts
        const existingToasts = document.querySelectorAll('.toast');
        existingToasts.forEach(toast => toast.remove());

        const toast = document.createElement('div');
        toast.className = `toast ${type}`;
        toast.innerHTML = `
            <div class="flex items-center">
                <span class="material-symbols-outlined mr-2">
                    ${type === 'success' ? 'check_circle' : type === 'error' ? 'error' : 'info'}
                </span>
                ${message}
            </div>
        `;

        document.body.appendChild(toast);

        // Show toast
        setTimeout(() => {
            toast.classList.add('show');
        }, 100);

        // Hide toast after 4 seconds
        setTimeout(() => {
            toast.classList.remove('show');
            setTimeout(() => {
                toast.remove();
            }, 300);
        }, 4000);
    }
}

// Initialize the app when DOM is loaded
document.addEventListener('DOMContentLoaded', () => {
    new LoginApp();
});