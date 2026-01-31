const { chromium } = require('playwright');
const path = require('path');

(async () => {
    const chromeProfileDir = process.env.HOME + '/Library/Application Support/Google/Chrome';
    
    console.log('Launching Chrome with your profile...');
    const browser = await chromium.launchPersistentContext(chromeProfileDir + '/Default', {
        headless: false,  // Need to see if login screen appears
        slowMo: 100
    });
    
    const page = await browser.newPage();
    
    try {
        console.log('Going to x.com/CheddarFlow...');
        await page.goto('https://x.com/CheddarFlow', { waitUntil: 'networkidle', timeout: 60000 });
        
        // Check if we're logged in
        const loginButton = await page.$('text="Sign in"');
        if (loginButton) {
            console.log('⚠️ Not logged in! Please log into x.com first.');
            await browser.close();
            process.exit(1);
        }
        
        // Wait for tweets to load
        await page.waitForSelector('article[data-testid="tweet"]', { timeout: 30000 });
        
        const tweets = await page.evaluate(() => {
            const items = [];
            document.querySelectorAll('article[data-testid="tweet"]').forEach(article => {
                const textEl = article.querySelector('[data-testid="tweetText"]');
                const timeEl = article.querySelector('time');
                
                if (textEl) {
                    items.push({
                        text: textEl.innerText,
                        time: timeEl?.getAttribute('datetime') || 'unknown',
                        displayTime: timeEl?.innerText || 'unknown'
                    });
                }
            });
            return items;
        });
        
        console.log('\n=== Real Cheddar Flow Tweets ===');
        tweets.slice(0, 10).forEach((t, i) => {
            console.log(`\n[${i+1}] ${t.displayTime}`);
            console.log(t.text);
        });
        
        // Save to file for processing
        const fs = require('fs');
        fs.writeFileSync('/tmp/cheddar-tweets.json', JSON.stringify(tweets, null, 2));
        console.log('\n✅ Saved to /tmp/cheddar-tweets.json');
        
    } catch (e) {
        console.error('Error:', e.message);
        await page.screenshot({ path: '/tmp/cheddar-error.png' });
        console.log('Screenshot saved to /tmp/cheddar-error.png');
    } finally {
        await browser.close();
    }
})();
