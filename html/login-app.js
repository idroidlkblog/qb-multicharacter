class LoginApp {
    constructor() {
        this.currentForm = 'login';
        this.isLoading = false;
        this.toastContainer = null;
        this.init();
    }

    init() {
        this.createToastContainer();
        this.bindEvents();
        this.setupPasswordToggles();
        this.setupFormAnimations();
        this.setupMessageListener();
    }

    createToastContainer() {
        this.toastContainer = document.getElementById('toast-container');
        if (!this.toastContainer) {
            this.toastContainer = document.createElement('div');
            this.toastContainer.id = 'toast-container';
            this.toastContainer.className = 'fixed top-6 right-6 z-50 space-y-3';
            document.body.appendChild(this.toastContainer);
        }
    }

    setupMessageListener() {
        window.addEventListener('message', (event) => {
            const data = event.data;
            
            if (data.action === 'loginResult') {
                if (data.result.success) {
                    this.showToast('Welcome back! Loading your characters...', 'success');
                    setTimeout(() => {
                        this.hideLoginUI();
                    }, 1500);
                } else {
                    this.showToast(data.result.message, 'error');
                }
            } else if (data.action === 'registerResult') {
                if (data.result.success) {
                    this.showToast('Account created successfully! You can now sign in.', 'success');
                    setTimeout(() => {
                        this.switchForm('login');
                        const emailInput = document.getElementById('login-email');
                        if (emailInput) {
                            emailInput.value = document.getElementById('register-email').value;
                            emailInput.focus();
                        }
                    }, 1500);
                } else {
                    this.showToast(data.result.message, 'error');
                }
            }
        });
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

        // Enhanced input interactions
        this.setupInputAnimations();
    }

    setupInputAnimations() {
        const inputs = document.querySelectorAll('input');
        inputs.forEach(input => {
            input.addEventListener('focus', () => {
                input.parentElement.classList.add('focused');
            });
            
            input.addEventListener('blur', () => {
                input.parentElement.classList.remove('focused');
            });
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
                
                // Add a subtle animation
                button.style.transform = 'scale(0.9)';
                setTimeout(() => {
                    button.style.transform = 'scale(1)';
                }, 100);
            });
        });
    }

    setupFormAnimations() {
        // Add staggered animations to form elements
        const animateElements = (container, delay = 100) => {
            const elements = container.querySelectorAll('.relative, button, .space-y-3 > div');
            elements.forEach((el, index) => {
                el.style.opacity = '0';
                el.style.transform = 'translateY(20px)';
                setTimeout(() => {
                    el.style.transition = 'all 0.4s ease-out';
                    el.style.opacity = '1';
                    el.style.transform = 'translateY(0)';
                }, index * delay);
            });
        };

        // Animate current form on load
        const currentForm = document.getElementById('login-form');
        if (currentForm && !currentForm.classList.contains('hidden')) {
            setTimeout(() => animateElements(currentForm), 200);
        }
    }

    switchForm(formType) {
        const loginForm = document.getElementById('login-form');
        const registerForm = document.getElementById('register-form');

        // Add exit animation
        const currentForm = formType === 'register' ? loginForm : registerForm;
        const newForm = formType === 'register' ? registerForm : loginForm;

        currentForm.style.transform = 'translateX(-20px)';
        currentForm.style.opacity = '0';
        
        setTimeout(() => {
            currentForm.classList.add('hidden');
            newForm.classList.remove('hidden');
            
            // Reset and animate new form
            newForm.style.transform = 'translateX(20px)';
            newForm.style.opacity = '0';
            
            setTimeout(() => {
                newForm.style.transition = 'all 0.4s ease-out';
                newForm.style.transform = 'translateX(0)';
                newForm.style.opacity = '1';
                
                // Animate form elements
                this.setupFormAnimations();
            }, 50);
        }, 200);

        this.currentForm = formType;
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

        const identifier = document.getElementById('login-email').value.trim();
        const password = document.getElementById('login-password').value;

        if (!this.validateLoginForm(identifier, password)) {
            return;
        }

        this.setLoading(true);

        try {
            // Send to parent frame (main NUI)
            window.parent.postMessage({
                type: 'login',
                data: {
                    email: identifier, // Server expects 'email' but now accepts username too
                    password: password
                }
            }, '*');

        } catch (error) {
            this.showToast('Connection error. Please try again.', 'error');
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
            // Send to parent frame (main NUI)
            window.parent.postMessage({
                type: 'register',
                data: {
                    username: username,
                    email: email,
                    password: password
                }
            }, '*');

        } catch (error) {
            this.showToast('Connection error. Please try again.', 'error');
            this.setLoading(false);
        }
    }

    validateLoginForm(identifier, password) {
        if (!identifier || !password) {
            this.showToast('Please fill in all fields.', 'warning');
            return false;
        }

        if (identifier.length < 3) {
            this.showToast('Please enter a valid email or username.', 'warning');
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

        if (!/^[a-zA-Z0-9_]+$/.test(username)) {
            this.showToast('Username can only contain letters, numbers, and underscores.', 'warning');
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

    setLoading(loading) {
        this.isLoading = loading;
        const overlay = document.getElementById('loading-overlay');
        const forms = document.querySelectorAll('form');
        
        if (loading) {
            overlay.classList.remove('hidden');
            forms.forEach(form => form.classList.add('loading'));
        } else {
            overlay.classList.add('hidden');
            forms.forEach(form => form.classList.remove('loading'));
        }
    }

    hideLoginUI() {
        const loginApp = document.getElementById('login-app');
        loginApp.style.transition = 'all 0.5s ease-out';
        loginApp.style.transform = 'scale(0.9)';
        loginApp.style.opacity = '0';
        
        setTimeout(() => {
            document.body.style.display = 'none';
        }, 500);
    }

    showToast(message, type = 'info') {
        // Create toast element
        const toast = document.createElement('div');
        toast.className = `toast ${type}`;
        
        // Get appropriate icon
        let icon = 'info';
        switch(type) {
            case 'success': icon = 'check_circle'; break;
            case 'error': icon = 'error'; break;
            case 'warning': icon = 'warning'; break;
            default: icon = 'info'; break;
        }
        
        toast.innerHTML = `
            <div class="flex items-center">
                <span class="material-symbols-outlined mr-3 text-xl">
                    ${icon}
                </span>
                <span class="flex-1">${message}</span>
            </div>
        `;

        // Add to container
        this.toastContainer.appendChild(toast);

        // Auto remove after 4 seconds
        setTimeout(() => {
            this.removeToast(toast);
        }, 4000);

        // Add click to dismiss
        toast.addEventListener('click', () => {
            this.removeToast(toast);
        });
    }

    removeToast(toast) {
        if (toast && toast.parentNode) {
            toast.classList.add('removing');
            setTimeout(() => {
                if (toast.parentNode) {
                    toast.parentNode.removeChild(toast);
                }
            }, 300);
        }
    }
}

// Initialize the app when DOM is loaded
document.addEventListener('DOMContentLoaded', () => {
    new LoginApp();
});