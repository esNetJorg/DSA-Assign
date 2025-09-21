// Car Rental System - JavaScript

// Global Variables
let currentRole = 'customer';
let currentUser = { id: 'customer1', name: 'John Doe' };
let currentView = 'dashboard';
let cars = [];
let reservations = [];
let cart = [];
let stats = {};
let selectedCar = null;

const API_BASE = 'http://localhost:8080/api';

// Initialize Application
document.addEventListener('DOMContentLoaded', function() {
    initializeApp();
});

async function initializeApp() {
    updateNavigation();
    updateUserInfo();
    await fetchInitialData();
    showView('dashboard');
}

// Role Management
function switchRole() {
    currentRole = currentRole === 'admin' ? 'customer' : 'admin';
    currentUser = currentRole === 'admin' 
        ? { id: 'admin1', name: 'Admin User' }
        : { id: 'customer1', name: 'John Doe' };
    
    updateNavigation();
    updateUserInfo();
    fetchInitialData();
    showView('dashboard');
    
    showNotification(`Switched to ${currentRole.toUpperCase()} role`, 'info');
}

function updateUserInfo() {
    document.getElementById('user-name').textContent = currentUser.name;
    document.getElementById('user-role').textContent = currentRole.toUpperCase();
}

function updateNavigation() {
    const navTabs = document.getElementById('nav-tabs');
    const adminTabs = `
        <button class="nav-tab" onclick="showView('dashboard')">
            <i class="fas fa-chart-bar"></i>
            Dashboard
        </button>
        <button class="nav-tab" onclick="showView('manage-cars')">
            <i class="fas fa-car"></i>
            Manage Cars
        </button>
        <button class="nav-tab" onclick="showView('manage-users')">
            <i class="fas fa-users"></i>
            Manage Users
        </button>
        <button class="nav-tab" onclick="showView('reservations')">
            <i class="fas fa-calendar"></i>
            Reservations
        </button>
    `;
    
    const customerTabs = `
        <button class="nav-tab" onclick="showView('dashboard')">
            <i class="fas fa-chart-bar"></i>
            Dashboard
        </button>
        <button class="nav-tab" onclick="showView('browse-cars')">
            <i class="fas fa-car"></i>
            Browse Cars
        </button>
        <button class="nav-tab" onclick="showView('cart')">
            <i class="fas fa-shopping-cart"></i>
            My Cart
        </button>
        <button class="nav-tab" onclick="showView('my-bookings')">
            <i class="fas fa-calendar"></i>
            My Bookings
        </button>
    `;
    
    navTabs.innerHTML = currentRole === 'admin' ? adminTabs : customerTabs;
}

// View Management
function showView(viewName) {
    // Hide all views
    document.querySelectorAll('.view-section').forEach(section => {
        section.classList.remove('active');
    });
    
    // Remove active class from all nav tabs
    document.querySelectorAll('.nav-tab').forEach(tab => {
        tab.classList.remove('active');
    });
    
    // Show selected view
    const viewElement = document.getElementById(`${viewName}-view`);
    if (viewElement) {
        viewElement.classList.add('active');
        currentView = viewName;
        
        // Add active class to current nav tab
        document.querySelectorAll('.nav-tab').forEach(tab => {
            if (tab.textContent.toLowerCase().includes(viewName.replace('-', ' ')) || 
                (viewName === 'dashboard' && tab.textContent.includes('Dashboard'))) {
                tab.classList.add('active');
            }
        });
        
        // Load view-specific data
        loadViewData(viewName);
    }
}

async function loadViewData(viewName) {
    switch(viewName) {
        case 'browse-cars':
        case 'manage-cars':
            await fetchCars();
            break;
        case 'reservations':
        case 'my-bookings':
            await fetchReservations();
            break;
        case 'cart':
            updateCartView();
            break;
        case 'dashboard':
            await fetchStats();
            updateDashboard();
            break;
    }
}

async function fetchInitialData() {
    try {
        await Promise.all([
            fetchCars(),
            currentRole === 'admin' ? fetchReservations() : Promise.resolve(),
            currentRole === 'admin' ? fetchStats() : Promise.resolve()
        ]);
        updateDashboard();
    } catch (error) {
        console.error('Error fetching initial data:', error);
        showNotification('Error loading data', 'error');
    }
}

// API Functions
async function fetchCars(filter = '', year = '') {
    try {
        showLoading('cars-loading');
        
        const params = new URLSearchParams();
        if (filter) params.append('filter_text', filter);
        if (year) params.append('year_filter', year);
        
        const response = await fetch(`${API_BASE}/cars?${params}`);
        const data = await response.json();
        
        if (data.success) {
            cars = data.data;
            updateCarsGrid();
        } else {
            showNotification('Failed to fetch cars: ' + data.message, 'error');
        }
    } catch (error) {
        console.error('Error fetching cars:', error);
        showNotification('Network error while fetching cars', 'error');
    } finally {
        hideLoading('cars-loading');
    }
}

async function fetchReservations() {
    try {
        const response = await fetch(`${API_BASE}/admin/reservations`);
        const data = await response.json();
        
        if (data.success) {
            reservations = data.data;
            updateReservationsGrid();
        } else {
            showNotification('Failed to fetch reservations: ' + data.message, 'error');
        }
    } catch (error) {
        console.error('Error fetching reservations:', error);
        showNotification('Network error while fetching reservations', 'error');
    }
}

async function fetchStats() {
    try {
        const response = await fetch(`${API_BASE}/admin/stats`);
        const data = await response.json();
        
        if (data.success) {
            stats = data.data;
        }
    } catch (error) {
        console.error('Error fetching stats:', error);
    }
}

async function addCar(carData) {
    try {
        const response = await fetch(`${API_BASE}/admin/cars`, {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify(carData)
        });
        const data = await response.json();
        
        if (data.success) {
            showNotification('Car added successfully!', 'success');
            await fetchCars();
            closeModal('add-car-modal');
            return true;
        } else {
            showNotification('Failed to add car: ' + data.message, 'error');
            return false;
        }
    } catch (error) {
        console.error('Error adding car:', error);
        showNotification('Network error while adding car', 'error');
        return false;
    }
}

async function addToCart(plate, startDate, endDate) {
    try {
        const response = await fetch(`${API_BASE}/customers/${currentUser.id}/cart`, {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify({
                plate,
                start_date: startDate,
                end_date: endDate
            })
        });
        const data = await response.json();
        
        if (data.success) {
            cart.push(data.data);
            updateCartCount();
            updateCartView();
            showNotification('Car added to cart!', 'success');
            closeModal('rent-car-modal');
            return true;
        } else {
            showNotification('Failed to add to cart: ' + data.message, 'error');
            return false;
        }
    } catch (error) {
        console.error('Error adding to cart:', error);
        showNotification('Network error while adding to cart', 'error');
        return false;
    }
}

async function placeReservation() {
    if (cart.length === 0) {
        showNotification('Cart is empty!', 'warning');
        return;
    }
    
    try {
        const response = await fetch(`${API_BASE}/customers/${currentUser.id}/reservations`, {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' }
        });
        const data = await response.json();
        
        if (data.success) {
            cart = [];
            updateCartCount();
            updateCartView();
            await fetchReservations();
            showNotification(`Reservation placed successfully! Total: $${data.data.total_amount}`, 'success');
        } else {
            showNotification('Failed to place reservation: ' + data.message, 'error');
        }
    } catch (error) {
        console.error('Error placing reservation:', error);
        showNotification('Network error while placing reservation', 'error');
    }
}

// UI Update Functions
function updateDashboard() {
    const statsContainer = document.getElementById('dashboard-stats');
    
    if (currentRole === 'admin') {
        statsContainer.innerHTML = `
            <div class="stat-card">
                <div class="stat-icon blue">
                    <i class="fas fa-car"></i>
                </div>
                <div class="stat-value">${stats.total_cars || 0}</div>
                <div class="stat-label">Total Cars</div>
                <div class="stat-subtitle">${stats.available_cars || 0} available</div>
            </div>
            
            <div class="stat-card">
                <div class="stat-icon green">
                    <i class="fas fa-users"></i>
                </div>
                <div class="stat-value">${stats.rented_cars || 0}</div>
                <div class="stat-label">Active Rentals</div>
                <div class="stat-subtitle">Currently rented</div>
            </div>
            
            <div class="stat-card">
                <div class="stat-icon purple">
                    <i class="fas fa-calendar"></i>
                </div>
                <div class="stat-value">${stats.total_reservations || 0}</div>
                <div class="stat-label">Reservations</div>
                <div class="stat-subtitle">${stats.confirmed_reservations || 0} confirmed</div>
            </div>
            
            <div class="stat-card">
                <div class="stat-icon orange">
                    <i class="fas fa-dollar-sign"></i>
                </div>
                <div class="stat-value">$${(stats.total_revenue || 0).toLocaleString()}</div>
                <div class="stat-label">Total Revenue</div>
                <div class="stat-subtitle">All time</div>
            </div>
        `;
    } else {
        const availableCars = cars.filter(car => car.status === 'AVAILABLE').length;
        const myBookings = reservations.filter(r => r.customer_id === currentUser.id).length;
        
        statsContainer.innerHTML = `
            <div class="stat-card">
                <div class="stat-icon blue">
                    <i class="fas fa-car"></i>
                </div>
                <div class="stat-value">${availableCars}</div>
                <div class="stat-label">Available Cars</div>
                <div class="stat-subtitle">Ready to rent</div>
            </div>
            
            <div class="stat-card">
                <div class="stat-icon purple">
                    <i class="fas fa-shopping-cart"></i>
                </div>
                <div class="stat-value">${cart.length}</div>
                <div class="stat-label">Cart Items</div>
                <div class="stat-subtitle">Ready to book</div>
            </div>
            
            <div class="stat-card">
                <div class="stat-icon green">
                    <i class="fas fa-calendar"></i>
                </div>
                <div class="stat-value">${myBookings}</div>
                <div class="stat-label">My Bookings</div>
                <div class="stat-subtitle">Active reservations</div>
            </div>
        `;
    }
    
    // Update activity text
    document.getElementById('available-cars-text').textContent = 
        `${cars.filter(car => car.status === 'AVAILABLE').length} cars available for rental`;
    document.getElementById('last-sync').textContent = new Date().toLocaleTimeString();
}

function updateCarsGrid() {
    const carsGrid = document.getElementById('cars-grid');
    const adminCarsGrid = document.getElementById('admin-cars-grid');
    
    if (cars.length === 0) {
        const emptyState = `
            <div class="empty-state">
                <i class="fas fa-car"></i>
                <h3>No cars found</h3>
                <p>Try adjusting your search criteria or add new cars.</p>
            </div>
        `;
        if (carsGrid) carsGrid.innerHTML = emptyState;
        if (adminCarsGrid) adminCarsGrid.innerHTML = emptyState;
        return;
    }
    
    const carsHTML = cars.map(car => createCarCard(car)).join('');
    if (carsGrid) carsGrid.innerHTML = carsHTML;
    if (adminCarsGrid) adminCarsGrid.innerHTML = carsHTML;
}

function createCarCard(car) {
    const isAdmin = currentRole === 'admin';
    const statusClass = `status-${car.status.toLowerCase()}`;
    
    return `
        <div class="car-card">
            <div class="car-image">
                <i class="fas fa-car"></i>
                <div class="car-status ${statusClass}">${car.status}</div>
            </div>
            
            <div class="car-details">
                <h3 class="car-title">${car.make} ${car.model}</h3>
                <p class="car-info">Year: ${car.year} | ${car.mileage.toLocaleString()} miles</p>
                <p class="car-price">$${car.daily_price}/day</p>
                <p style="color: #666; font-size: 0.8rem; margin-bottom: 1rem;">Plate: ${car.plate}</p>
                
                <div class="car-actions">
                    ${isAdmin ? `
                        <button class="btn btn-primary" onclick="editCar('${car.plate}')">
                            <i class="fas fa-edit"></i>
                            Edit
                        </button>
                        <button class="btn btn-danger" onclick="deleteCar('${car.plate}')">
                            <i class="fas fa-trash"></i>
                        </button>
                    ` : car.status === 'AVAILABLE' ? `
                        <button class="btn btn-primary" onclick="rentCar('${car.plate}')">
                            <i class="fas fa-calendar-plus"></i>
                            Rent This Car
                        </button>
                    ` : `
                        <button class="btn btn-secondary" disabled>
                            <i class="fas fa-ban"></i>
                            Not Available
                        </button>
                    `}
                </div>
            </div>
        </div>
    `;
}

function updateCartView() {
    const cartItems = document.getElementById('cart-items');
    const cartSummary = document.getElementById('cart-summary');
    const checkoutBtn = document.getElementById('checkout-btn');
    
    if (cart.length === 0) {
        cartItems.innerHTML = `
            <div class="empty-state">
                <i class="fas fa-shopping-cart"></i>
                <h3>Your cart is empty</h3>
                <p>Browse cars and add them to your cart to get started.</p>
                <button class="btn btn-primary" onclick="showView('browse-cars')">
                    <i class="fas fa-car"></i>
                    Browse Cars
                </button>
            </div>
        `;
        cartSummary.style.display = 'none';
        checkoutBtn.disabled = true;
        return;
    }
    
    const cartHTML = cart.map((item, index) => `
        <div class="cart-item">
            <div class="cart-item-info">
                <h3>${item.plate}</h3>
                <div class="cart-item-dates">
                    ${item.start_date} to ${item.end_date}
                </div>
            </div>
            <div class="cart-item-price">$${item.estimated_price}</div>
            <button class="btn btn-danger" onclick="removeFromCart(${index})">
                <i class="fas fa-trash"></i>
            </button>
        </div>
    `).join('');
    
    cartItems.innerHTML = cartHTML;
    
    const totalAmount = cart.reduce((sum, item) => sum + item.estimated_price, 0);
    document.getElementById('total-items').textContent = cart.length;
    document.getElementById('total-amount').textContent = `$${totalAmount.toFixed(2)}`;
    
    cartSummary.style.display = 'block';
    checkoutBtn.disabled = false;
}

function updateReservationsGrid() {
    const reservationsGrid = document.getElementById('reservations-grid');
    const myBookingsGrid = document.getElementById('my-bookings-grid');
    
    const filteredReservations = currentRole === 'admin' 
        ? reservations 
        : reservations.filter(r => r.customer_id === currentUser.id);
    
    if (filteredReservations.length === 0) {
        const emptyState = `
            <div class="empty-state">
                <i class="fas fa-calendar"></i>
                <h3>No reservations found</h3>
                <p>${currentRole === 'admin' ? 'No reservations have been made yet.' : 'You have no active bookings.'}</p>
            </div>
        `;
        if (reservationsGrid) reservationsGrid.innerHTML = emptyState;
        if (myBookingsGrid) myBookingsGrid.innerHTML = emptyState;
        return;
    }
    
    const reservationsHTML = filteredReservations.map(reservation => createReservationCard(reservation)).join('');
    if (reservationsGrid) reservationsGrid.innerHTML = reservationsHTML;
    if (myBookingsGrid) myBookingsGrid.innerHTML = reservationsHTML;
}

function createReservationCard(reservation) {
    const statusClass = `status-${reservation.status.toLowerCase()}`;
    
    return `
        <div class="reservation-card">
            <div class="reservation-header">
                <div class="reservation-id">Reservation #${reservation.reservation_id.slice(-8)}</div>
                <div class="car-status ${statusClass}">${reservation.status}</div>
            </div>
            
            <div class="reservation-grid">
                <div class="reservation-field">
                    <h4>Customer</h4>
                    <p>${reservation.customer_id}</p>
                </div>
                <div class="reservation-field">
                    <h4>Car</h4>
                    <p>${reservation.plate}</p>
                </div>
                <div class="reservation-field">
                    <h4>Start Date</h4>
                    <p>${reservation.start_date}</p>
                </div>
                <div class="reservation-field">
                    <h4>End Date</h4>
                    <p>${reservation.end_date}</p>
                </div>
                <div class="reservation-field">
                    <h4>Total Price</h4>
                    <p style="color: #4CAF50; font-weight: 700;">$${reservation.total_price}</p>
                </div>
                <div class="reservation-field">
                    <h4>Created</h4>
                    <p>${new Date(reservation.created_at).toLocaleDateString()}</p>
                </div>
            </div>
        </div>
    `;
}

function updateCartCount() {
    document.getElementById('cart-count').textContent = cart.length;
}

// Event Handlers
function handleSearch() {
    const searchTerm = document.getElementById('search-input').value;
    const yearFilter = document.getElementById('year-filter').value;
    fetchCars(searchTerm, yearFilter);
}

function handleAddCar(event) {
    event.preventDefault();
    
    const carData = {
        plate: document.getElementById('car-plate').value,
        make: document.getElementById('car-make').value,
        model: document.getElementById('car-model').value,
        year: parseInt(document.getElementById('car-year').value),
        daily_price: parseFloat(document.getElementById('car-price').value),
        mileage: parseInt(document.getElementById('car-mileage').value),
        status: document.getElementById('car-status').value
    };
    
    addCar(carData);
}

function handleRentCar(event) {
    event.preventDefault();
    
    const startDate = document.getElementById('rent-start-date').value;
    const endDate = document.getElementById('rent-end-date').value;
    
    if (!selectedCar || !startDate || !endDate) {
        showNotification('Please fill all required fields', 'warning');
        return;
    }
    
    if (new Date(startDate) >= new Date(endDate)) {
        showNotification('End date must be after start date', 'warning');
        return;
    }
    
    addToCart(selectedCar.plate, startDate, endDate);
}

function rentCar(plate) {
    selectedCar = cars.find(car => car.plate === plate);
    if (!selectedCar) return;
    
    // Populate car info in modal
    document.getElementById('selected-car-info').innerHTML = `
        <div class="car-card">
            <div class="car-details">
                <h3 class="car-title">${selectedCar.make} ${selectedCar.model}</h3>
                <p class="car-info">Year: ${selectedCar.year} | ${selectedCar.mileage.toLocaleString()} miles</p>
                <p class="car-price">$${selectedCar.daily_price}/day</p>
                <p style="color: #666; font-size: 0.8rem;">Plate: ${selectedCar.plate}</p>
            </div>
        </div>
    `;
    
    // Set minimum date to today
    const today = new Date().toISOString().split('T')[0];
    document.getElementById('rent-start-date').min = today;
    document.getElementById('rent-end-date').min = today;
    
    // Add event listeners for date changes
    document.getElementById('rent-start-date').onchange = updateRentalSummary;
    document.getElementById('rent-end-date').onchange = updateRentalSummary;
    
    showModal('rent-car-modal');
}

function updateRentalSummary() {
    const startDate = document.getElementById('rent-start-date').value;
    const endDate = document.getElementById('rent-end-date').value;
    const summary = document.getElementById('rental-summary');
    
    if (!startDate || !endDate || !selectedCar) {
        summary.style.display = 'none';
        return;
    }
    
    const start = new Date(startDate);
    const end = new Date(endDate);
    const days = Math.ceil((end - start) / (1000 * 60 * 60 * 24)) + 1;
    const total = days * selectedCar.daily_price;
    
    if (days > 0) {
        document.getElementById('rental-days').textContent = days;
        document.getElementById('daily-rate').textContent = `$${selectedCar.daily_price}`;
        document.getElementById('estimated-total').textContent = `$${total.toFixed(2)}`;
        summary.style.display = 'block';
    } else {
        summary.style.display = 'none';
    }
}

function removeFromCart(index) {
    cart.splice(index, 1);
    updateCartCount();
    updateCartView();
    showNotification('Item removed from cart', 'info');
}

function editCar(plate) {
    // TODO: Implement edit car functionality
    showNotification('Edit car functionality coming soon', 'info');
}

async function deleteCar(plate) {
    if (!confirm(`Are you sure you want to delete car ${plate}?`)) return;
    
    try {
        const response = await fetch(`${API_BASE}/admin/cars/${plate}`, {
            method: 'DELETE'
        });
        const data = await response.json();
        
        if (data.success) {
            showNotification('Car deleted successfully!', 'success');
            await fetchCars();
        } else {
            showNotification('Failed to delete car: ' + data.message, 'error');
        }
    } catch (error) {
        console.error('Error deleting car:', error);
        showNotification('Network error while deleting car', 'error');
    }
}

async function createBatchUsers() {
    const userType = document.getElementById('batch-user-type').value;
    const count = parseInt(document.getElementById('batch-user-count').value);
    
    const users = [];
    for (let i = 1; i <= count; i++) {
        users.push({
            user_id: `${userType}${Date.now()}_${i}`,
            name: `${userType.charAt(0).toUpperCase() + userType.slice(1)} User ${i}`,
            email: `${userType}${i}@example.com`,
            role: userType.toUpperCase(),
            created_at: ""
        });
    }
    
    try {
        const response = await fetch(`${API_BASE}/admin/users`, {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify({ users })
        });
        const data = await response.json();
        
        if (data.success) {
            showNotification(`${data.users_created} users created successfully!`, 'success');
            // Reset form
            document.getElementById('batch-user-count').value = '1';
        } else {
            showNotification('Failed to create users: ' + data.message, 'error');
        }
    } catch (error) {
        console.error('Error creating users:', error);
        showNotification('Network error while creating users', 'error');
    }
}

// Modal Functions
function showModal(modalId) {
    document.getElementById(modalId).classList.add('active');
}

function closeModal(modalId) {
    document.getElementById(modalId).classList.remove('active');
    
    // Reset forms when closing modals
    if (modalId === 'add-car-modal') {
        document.querySelector('#add-car-modal form').reset();
    } else if (modalId === 'rent-car-modal') {
        document.querySelector('#rent-car-modal form').reset();
        document.getElementById('rental-summary').style.display = 'none';
        selectedCar = null;
    }
}

function showAddCarModal() {
    if (currentRole !== 'admin') {
        showNotification('Admin access required', 'warning');
        return;
    }
    showModal('add-car-modal');
}

function showAddUserModal() {
    if (currentRole !== 'admin') {
        showNotification('Admin access required', 'warning');
        return;
    }
    showNotification('Use the batch user creation form below', 'info');
}

// Utility Functions
function showLoading(elementId) {
    const element = document.getElementById(elementId);
    if (element) {
        element.style.display = 'flex';
    }
}

function hideLoading(elementId) {
    const element = document.getElementById(elementId);
    if (element) {
        element.style.display = 'none';
    }
}

function showNotification(message, type = 'info') {
    // Remove existing notifications
    document.querySelectorAll('.notification').forEach(n => n.remove());
    
    const notification = document.createElement('div');
    notification.className = `notification ${type}`;
    notification.innerHTML = `
        <i class="fas fa-${getNotificationIcon(type)}"></i>
        ${message}
    `;
    
    document.body.appendChild(notification);
    
    // Auto remove after 5 seconds
    setTimeout(() => {
        if (notification.parentNode) {
            notification.parentNode.removeChild(notification);
        }
    }, 5000);
}

function getNotificationIcon(type) {
    const icons = {
        success: 'check-circle',
        error: 'exclamation-circle',
        warning: 'exclamation-triangle',
        info: 'info-circle'
    };
    return icons[type] || 'info-circle';
}

// Event Listeners
// Close modals when clicking outside
document.addEventListener('click', function(event) {
    if (event.target.classList.contains('modal')) {
        const modalId = event.target.id;
        closeModal(modalId);
    }
});

// Handle escape key for modals
document.addEventListener('keydown', function(event) {
    if (event.key === 'Escape') {
        document.querySelectorAll('.modal.active').forEach(modal => {
            closeModal(modal.id);
        });
    }
});

// Search debouncing
let searchTimeout;
function handleSearch() {
    clearTimeout(searchTimeout);
    searchTimeout = setTimeout(() => {
        const searchTerm = document.getElementById('search-input').value;
        const yearFilter = document.getElementById('year-filter').value;
        fetchCars(searchTerm, yearFilter);
    }, 300);
}

// Auto-refresh data every 30 seconds
setInterval(async () => {
    if (currentView === 'dashboard' || currentView === 'browse-cars' || currentView === 'manage-cars') {
        await fetchCars();
    }
    if (currentRole === 'admin' && (currentView === 'dashboard' || currentView === 'reservations')) {
        await fetchReservations();
        await fetchStats();
    }
    updateDashboard();
}, 30000);

// Initialize cart count
updateCartCount();