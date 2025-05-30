import { authAPI, marketAPI } from './api.js';

// Üye olma işlemi
async function registerUser(name, surname, username, email, password) {
    try {
        console.log('Kayıt isteği gönderiliyor:', { name, surname, username, email });
        const response = await authAPI.register({ name, surname, username, email, password });
        console.log('Kayıt yanıtı:', response);
        alert('Kayıt başarılı! Giriş yapabilirsiniz.');
        window.location.href = 'login.html';
    } catch (error) {
        console.error('Kayıt hatası:', error);
        alert(error.message || 'Kayıt sırasında bir hata oluştu');
    }
}

// Giriş yapma işlemi
async function loginUser(email, password) {
    try {
        const response = await authAPI.login({ email, password });
        console.log('Giriş başarılı:', response);

        // Token ve kullanıcı bilgilerini kaydet
        localStorage.setItem('token', response.token);
        localStorage.setItem('user', JSON.stringify(response.user));

        // Başarılı giriş mesajı göster
        alert('Giriş başarılı! Profil sayfasına yönlendiriliyorsunuz...');

        // Profil sayfasına yönlendir
        window.location.href = 'profilim.html';
    } catch (error) {
        console.error('Giriş hatası:', error);
        alert(error.message || 'Giriş sırasında bir hata oluştu');
    }
}

// Profil bilgilerini güncelle
async function updateProfileInfo() {
    try {
        const token = localStorage.getItem('token');
        if (!token) {
            console.log('Token bulunamadı');
            return;
        }

        const response = await fetch('http://localhost:5000/api/user/profile', {
            method: 'GET',
            headers: {
                'Authorization': `Bearer ${token}`,
                'Content-Type': 'application/json'
            }
        });

        if (!response.ok) {
            throw new Error('Profil bilgileri alınamadı');
        }

        const userData = await response.json();
        console.log('Profil bilgileri:', userData);

        // Profil bilgilerini güncelle
        document.getElementById('profile-name').textContent = userData.name || '';
        document.getElementById('profile-surname').textContent = userData.surname || '';
        document.getElementById('profile-username').textContent = userData.username || '';
        document.getElementById('profile-email').textContent = userData.email || '';
        document.getElementById('profile-balance').textContent = userData.balance ? `${userData.balance.toFixed(2)} TL` : '0.00 TL';

        // Portföy bilgilerini güncelle
        if (userData.portfolio) {
            updatePortfolio(userData.portfolio);
        }

        // İşlem geçmişini güncelle
        if (userData.transactions) {
            updateTransactionHistory(userData.transactions);
        }
    } catch (error) {
        console.error('Profil bilgileri güncellenirken hata:', error);
        alert('Profil bilgileri yüklenirken bir hata oluştu');
    }
}

// Portföy tablosunu güncelle
async function updatePortfolio(portfolio) {
    const portfolioTable = document.getElementById('portfolio-table');
    if (!portfolioTable) return;

    const tbody = portfolioTable.querySelector('tbody');
    tbody.innerHTML = '';

    let totalPortfolioValue = 0;
    let totalDailyChange = 0;

    for (const stock of portfolio) {
        // Güncel fiyat bilgisini al
        const currentPrice = await getCurrentStockPrice(stock.symbol);
        const totalValue = stock.quantity * currentPrice;
        const profitLoss = ((currentPrice - stock.averagePrice) / stock.averagePrice) * 100;
        
        totalPortfolioValue += totalValue;
        totalDailyChange += profitLoss;

        const row = document.createElement('tr');
        row.innerHTML = `
            <td>${stock.symbol}</td>
            <td>${stock.quantity}</td>
            <td>${stock.averagePrice.toFixed(2)}</td>
            <td>${currentPrice.toFixed(2)}</td>
            <td>${totalValue.toFixed(2)}</td>
            <td class="${profitLoss >= 0 ? 'positive-change' : 'negative-change'}">
                ${profitLoss.toFixed(2)}%
            </td>
        `;
        tbody.appendChild(row);
    }

    // Toplam portföy değerini ve günlük değişimi güncelle
    document.getElementById('total-portfolio-value').textContent = `${totalPortfolioValue.toFixed(2)} TL`;
    document.getElementById('daily-change').textContent = 
        `${totalDailyChange >= 0 ? '+' : ''}${totalDailyChange.toFixed(2)}%`;
    document.getElementById('daily-change').className = 
        totalDailyChange >= 0 ? 'positive-change' : 'negative-change';
}

// İşlem geçmişini güncelle
function updateTransactionHistory(transactions) {
    const transactionTable = document.getElementById('transaction-table');
    if (!transactionTable) return;

    const tbody = transactionTable.querySelector('tbody');
    tbody.innerHTML = '';

    transactions.forEach(transaction => {
        const row = document.createElement('tr');
        row.innerHTML = `
            <td>${new Date(transaction.date).toLocaleString()}</td>
            <td>${transaction.type === 'buy' ? 'Alış' : 'Satış'}</td>
            <td>${transaction.symbol}</td>
            <td>${transaction.quantity}</td>
            <td>${transaction.price.toFixed(2)}</td>
            <td>${(transaction.quantity * transaction.price).toFixed(2)}</td>
        `;
        tbody.appendChild(row);
    });
}

// Hisse senedi güncel fiyatını al
async function getCurrentStockPrice(symbol) {
    try {
        const response = await marketAPI.getStockPrice(symbol);
        return response.price;
    } catch (error) {
        console.error('Fiyat bilgisi alınamadı:', error);
        return 0;
    }
}

// Satın alma işlemi
export async function buyInvestment(amount, type) {
    try {
        const token = localStorage.getItem('token');
        if (!token) {
            alert('Lütfen önce giriş yapın');
            window.location.href = 'login.html';
            return;
        }

        console.log('Satın alma isteği gönderiliyor:', { amount, type });

        const response = await fetch('http://localhost:5000/api/market/buy', {
            method: 'POST',
            headers: {
                'Authorization': `Bearer ${token}`,
                'Content-Type': 'application/json'
            },
            body: JSON.stringify({
                amount: parseFloat(amount),
                type: type
            })
        });

        console.log('Sunucu yanıtı:', response);

        const data = await response.json();
        console.log('Satın alma yanıtı:', data);
        
        if (!response.ok) {
            throw new Error(data.message || 'Satın alma işlemi başarısız');
        }

        // Başarılı mesajını göster
        const successMessage = document.getElementById('success-message');
        if (successMessage) {
            successMessage.style.display = 'block';
        }

        // Kullanıcı bilgilerini güncelle
        localStorage.setItem('user', JSON.stringify(data.user));

        // 2 saniye sonra profil sayfasına yönlendir
        setTimeout(() => {
            window.location.href = 'profilim.html';
        }, 2000);
    } catch (error) {
        console.error('Satın alma hatası:', error);
        throw error;
    }
}

// Çıkış yapma işlemi
function logout() {
    localStorage.removeItem('token');
    localStorage.removeItem('user');
    window.location.href = 'login.html';
}

// Grafikleri oluştur ve güncelle
async function initializeCharts() {
    try {
        // Borsa endeksleri verilerini al
        const indicesResponse = await fetch('http://localhost:3000/api/market/indices');
        const indices = await indicesResponse.json();

        // Grafik verilerini al
        const chartResponse = await fetch(`http://localhost:3000/api/market/chart-data/${indices[0].symbol}`);
        const chartData = await chartResponse.json();

        // Piyasa durumu verilerini al
        const marketResponse = await fetch('http://localhost:3000/api/market/market-status');
        const marketData = await marketResponse.json();

        // Fiyat grafiği
        const priceChart = new Chart(document.getElementById('priceChart'), {
            type: 'line',
            data: {
                labels: chartData.map(item => item.time),
                datasets: [{
                    label: 'Fiyat',
                    data: chartData.map(item => item.close),
                    borderColor: '#ffd700',
                    tension: 0.1,
                    pointRadius: 0,
                    borderWidth: 2
                }]
            },
            options: {
                responsive: true,
                maintainAspectRatio: false,
                animation: {
                    duration: 1000
                }
            }
        });

        // Hacim grafiği
        const volumeChart = new Chart(document.getElementById('volumeChart'), {
            type: 'bar',
            data: {
                labels: chartData.map(item => item.time),
                datasets: [{
                    label: 'Hacim',
                    data: chartData.map(item => item.high - item.low),
                    backgroundColor: '#ffd700'
                }]
            },
            options: {
                responsive: true,
                maintainAspectRatio: false,
                animation: {
                    duration: 1000
                }
            }
        });

        // Piyasa durumu grafiği
        const marketChart = new Chart(document.getElementById('marketChart'), {
            type: 'doughnut',
            data: {
                labels: ['Toplam Hacim', 'Toplam İşlem'],
                datasets: [{
                    data: [marketData.totalVolume, marketData.totalTrades],
                    backgroundColor: ['#ffd700', '#ffa500']
                }]
            },
            options: {
                responsive: true,
                maintainAspectRatio: false,
                animation: {
                    duration: 1000
                }
            }
        });

        // Her 1 saniyede bir verileri güncelle
        setInterval(async () => {
            const newIndices = await fetch('http://localhost:3000/api/market/indices').then(res => res.json());
            const newChartData = await fetch(`http://localhost:3000/api/market/chart-data/${newIndices[0].symbol}`).then(res => res.json());
            const newMarketData = await fetch('http://localhost:3000/api/market/market-status').then(res => res.json());

            // Grafikleri güncelle
            priceChart.data.labels = newChartData.map(item => item.time);
            priceChart.data.datasets[0].data = newChartData.map(item => item.close);
            priceChart.update();

            volumeChart.data.labels = newChartData.map(item => item.time);
            volumeChart.data.datasets[0].data = newChartData.map(item => item.high - item.low);
            volumeChart.update();

            marketChart.data.datasets[0].data = [newMarketData.totalVolume, newMarketData.totalTrades];
            marketChart.update();
        }, 1000); // 1 saniyede bir güncelle
    } catch (error) {
        console.error('Grafik verileri alınırken hata:', error);
    }
}

// Anlık Piyasa Verileri (market-dashboard) için canlı veri
let lastMarketPrices = {};
async function updateMarketDashboard() {
    try {
        const response = await fetch('http://localhost:3000/api/market/popular');
        const coins = await response.json();
        const dashboard = document.getElementById('market-dashboard');
        if (!dashboard) return;
        dashboard.innerHTML = coins.map(coin => {
            const last = lastMarketPrices[coin.symbol] || coin.price;
            const up = coin.price > last;
            const down = coin.price < last;
            lastMarketPrices[coin.symbol] = coin.price;
            return `
                <div class="coin ${up ? 'up' : down ? 'down' : ''}">
                    <strong>${coin.symbol.replace('USDT','')}:</strong> <span class="coin-price">$${coin.price.toLocaleString(undefined, {minimumFractionDigits: 2, maximumFractionDigits: 2})}</span>
                    <span class="coin-change ${coin.change >= 0 ? 'up' : 'down'}">${coin.change >= 0 ? '+' : ''}${coin.change.toFixed(2)}%</span>
                </div>
            `;
        }).join('');
        setTimeout(updateMarketDashboard, 1000);
    } catch (error) {
        setTimeout(updateMarketDashboard, 3000);
    }
}

// Anlık canlı ticker kutuları (sadece live-ticker için)
let lastTickerPrices = {};
async function updateLiveTicker() {
    try {
        const response = await fetch('http://localhost:3000/api/market/live-ticker');
        const coins = await response.json();
        const ticker = document.getElementById('live-ticker');
        if (!ticker) return;
        ticker.innerHTML = coins.map(coin => {
            const last = lastTickerPrices[coin.symbol] || coin.price;
            const up = coin.price > last;
            const down = coin.price < last;
            lastTickerPrices[coin.symbol] = coin.price;
            return `
                <div class="live-coin ${up ? 'up' : down ? 'down' : ''}">
                    <span class="live-symbol">${coin.symbol.replace('USDT','')}</span>
                    <span class="live-price">$${coin.price.toLocaleString(undefined, {minimumFractionDigits: 2, maximumFractionDigits: 2})}</span>
                    <span class="live-change ${coin.change >= 0 ? 'up' : 'down'}">${coin.change >= 0 ? '+' : ''}${coin.change.toFixed(2)}%</span>
                </div>
            `;
        }).join('');
        setTimeout(updateLiveTicker, 1000);
    } catch (error) {
        setTimeout(updateLiveTicker, 3000);
    }
}

// Kripto haberlerini çek ve göster (yatay slider)
async function updateCryptoNews() {
    try {
        const response = await fetch('http://localhost:3000/api/market/crypto-news');
        const news = await response.json();
        const newsTrack = document.getElementById('crypto-news-track');
        if (!newsTrack) return;

        newsTrack.innerHTML = news.map(item => `
            <div class="news-card" onclick="window.open('${item.url}', '_blank')">
                ${item.urlToImage ? `<img src="${item.urlToImage}" alt="${item.title}">` : ''}
                <h3>${item.title}</h3>
                <p>${item.description || ''}</p>
                <div class="news-meta">
                    <span>${new Date(item.publishedAt).toLocaleDateString()}</span>
                    <span>${item.source && item.source.name ? item.source.name : ''}</span>
                </div>
            </div>
        `).join('');

        // Her 5 dakikada bir haberleri güncelle
        setTimeout(updateCryptoNews, 300000);
    } catch (error) {
        console.error('Haberler yüklenirken hata:', error);
        setTimeout(updateCryptoNews, 60000); // Hata durumunda 1 dakika sonra tekrar dene
    }
}

// Kullanıcı kontrolü ve avatar gösterimi
function checkUser() {
    const userString = localStorage.getItem('user');
    const loginLink = document.querySelector('.login-link');
    const userMenu = document.querySelector('.user-menu');
    const userAvatar = document.querySelector('.user-avatar');

    if (userString) {
        const user = JSON.parse(userString);
        if (loginLink) loginLink.style.display = 'none';
        if (userMenu) {
            userMenu.style.display = 'block';
            if (userAvatar) {
                // Kullanıcının adının ilk harfini büyük harf olarak göster
                const firstLetter = (user.name || user.username || '').charAt(0).toUpperCase();
                userAvatar.textContent = firstLetter;
            }
        }
    } else {
        if (loginLink) loginLink.style.display = 'block';
        if (userMenu) userMenu.style.display = 'none';
    }
}

// Sayfa yüklendiğinde
document.addEventListener('DOMContentLoaded', () => {
    console.log('Sayfa yüklendi');
    checkUser(); // Kullanıcı kontrolünü yap

    // Üye olma formu
    const registerForm = document.getElementById('register-form');
    if (registerForm) {
        registerForm.addEventListener('submit', async (e) => {
            e.preventDefault();
            const name = document.getElementById('name').value;
            const surname = document.getElementById('surname').value;
            const username = document.getElementById('username').value;
            const email = document.getElementById('email').value;
            const password = document.getElementById('password').value;
            await registerUser(name, surname, username, email, password);
        });
    }

    // Giriş formu
    const loginForm = document.getElementById('login-form');
    if (loginForm) {
        loginForm.addEventListener('submit', async (e) => {
            e.preventDefault();
            const email = document.getElementById('email').value;
            const password = document.getElementById('password').value;
            await loginUser(email, password);
        });
    }

    // Çıkış butonu
    const logoutButton = document.getElementById('logout-button');
    if (logoutButton) {
        logoutButton.addEventListener('click', logout);
    }

    // Profil sayfası kontrolü
    if (window.location.pathname.includes('profilim.html')) {
        const token = localStorage.getItem('token');
        const loginRequired = document.getElementById('login-required');
        const profileContent = document.getElementById('profile-content');

        if (!token) {
            if (loginRequired) loginRequired.style.display = 'flex';
            if (profileContent) profileContent.style.display = 'none';
        } else {
            if (loginRequired) loginRequired.style.display = 'none';
            if (profileContent) profileContent.style.display = 'block';
            // Profil bilgilerini yükle
            updateProfileInfo();
        }
    }

    // Satın alma formu
    const buyButton = document.getElementById('buy-button');
    if (buyButton) {
        console.log('Satın alma butonu bulundu');
        buyButton.addEventListener('click', () => {
            console.log('Satın alma butonuna tıklandı');
            const amount = document.getElementById('amount').value;
            const type = document.getElementById('type').value;

            console.log('Form değerleri:', { amount, type });

            if (!amount || !type) {
                alert('Lütfen tüm alanları doldurun');
                return;
            }

            buyInvestment(amount, type);
        });
    }

    // Sayfa yüklendiğinde grafikleri başlat
    initializeCharts();

    // Ana sayfada isek canlı verileri ve haberleri başlat
    if (window.location.pathname.endsWith('index.html') || window.location.pathname.endsWith('/')) {
        updateMarketDashboard();
        updateCryptoNews(); // Haberleri başlat
    }

    updateLiveTicker();
});
