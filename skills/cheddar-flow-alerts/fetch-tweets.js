const { chromium } = require('playwright');

(async () => {
    const browser = await chromium.launch({ 
        headless: true,
        args: ['--disable-blink-features=AutomationControlled']
    });
    
    const context = await browser.newContext({
        userAgent: 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36'
    });
    
    const page = await context.newPage();
    
    try {
        console.log('Fetching with stealth mode...');
        
        await page.addInitScript(() => {
            Object.defineProperty(navigator, 'webdriver', { get: () => undefined });
        });
        
        await page.goto('https://x.com/CheddarFlow', { 
            waitUntil: 'networkidle', 
            timeout: 45000 
        });
        
        await page.waitForSelector('article[data-testid="tweet"]', { timeout: 20000 });
        
        const tweets = await page.evaluate(() => {
            return Array.from(document.querySelectorAll('article[data-testid="tweet"]')).slice(0, 5).map(article => {
                const textEl = article.querySelector('[data-testid="tweetText"]');
                const timeEl = article.querySelector('time');
                const linkEl = article.querySelector('a[href*="/status/"]');
                return {
                    text: textEl?.innerText || '',
                    time: timeEl?.innerText || '',
                    url: linkEl ? 'https://x.com' + linkEl.getAttribute('href') : ''
                };
            });
        });
        
        console.log(JSON.stringify({ tweets }, null, 2));
        
    } catch (e) {
        console.error('Error:', e.message);
        const html = await page.content();
        console.log('HTML preview:', html.substring(0, 1000));
    } finally {
        await browser.close();
    }
})();
