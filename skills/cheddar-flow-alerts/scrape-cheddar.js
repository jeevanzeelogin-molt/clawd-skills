const { chromium } = require('playwright');

(async () => {
    console.log('Launching browser...');
    const browser = await chromium.launch({ headless: true });
    const page = await browser.newPage();
    
    // List of nitter instances to try
    const nitterInstances = [
        'https://nitter.privacydev.net',
        'https://nitter.net',
        'https://nitter.moomoo.me'
    ];
    
    let tweets = [];
    
    for (const instance of nitterInstances) {
        try {
            console.log(`Trying ${instance}/CheddarFlow...`);
            await page.goto(`${instance}/CheddarFlow`, { waitUntil: 'networkidle', timeout: 30000 });
            
            // Check if we got tweets
            const hasTweets = await page.$('.timeline-item') !== null;
            
            if (hasTweets) {
                tweets = await page.evaluate(() => {
                    const items = [];
                    document.querySelectorAll('.timeline-item').forEach(item => {
                        const content = item.querySelector('.tweet-content');
                        const dateEl = item.querySelector('.tweet-date');
                        if (content) {
                            items.push({
                                text: content.innerText.trim(),
                                time: dateEl?.innerText?.trim() || 'unknown',
                                date: dateEl?.getAttribute('title') || 'unknown'
                            });
                        }
                    });
                    return items;
                });
                
                if (tweets.length > 0) {
                    console.log(`Found ${tweets.length} tweets from ${instance}`);
                    break;
                }
            }
        } catch (e) {
            console.error(`Failed ${instance}: ${e.message}`);
        }
    }
    
    if (tweets.length === 0) {
        console.log('No tweets found on any nitter instance');
    } else {
        console.log('\n=== Recent Cheddar Flow Tweets ===');
        tweets.slice(0, 5).forEach((t, i) => {
            console.log(`\n[${i+1}] ${t.time}`);
            console.log(t.text.substring(0, 200) + (t.text.length > 200 ? '...' : ''));
        });
    }
    
    await browser.close();
})();
