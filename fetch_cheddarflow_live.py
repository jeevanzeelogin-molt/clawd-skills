import asyncio
import json
import re
from datetime import datetime, timedelta
from playwright.async_api import async_playwright

async def fetch_cheddarflow_posts():
    posts_data = []
    
    async with async_playwright() as p:
        # Launch browser directly (no CDP needed)
        browser = await p.chromium.launch(headless=True)
        
        # Create a new context and page
        context = await browser.new_context(viewport={"width": 1920, "height": 1080})
        page = await context.new_page()
        
        print("Navigating to CheddarFlow X page...")
        await page.goto("https://x.com/CheddarFlow")
        
        # Wait for page to load
        print("Waiting for page to load...")
        await page.wait_for_timeout(5000)
        
        # Take initial screenshot
        await page.screenshot(path="/Users/nemotaka/clawd/cheddarflow_initial.png")
        print("Initial screenshot saved")
        
        # Scroll and collect posts
        scroll_count = 0
        max_scrolls = 20  # Limit for testing
        seen_posts = set()
        
        while scroll_count < max_scrolls:
            print(f"\n--- Scroll {scroll_count + 1} ---")
            
            # Get all visible posts
            posts = await page.query_selector_all('article[data-testid="tweet"]')
            print(f"Found {len(posts)} posts on screen")
            
            for i, post in enumerate(posts):
                try:
                    # Get post text
                    text_elem = await post.query_selector('[data-testid="tweetText"]')
                    if not text_elem:
                        continue
                    
                    text = await text_elem.inner_text()
                    
                    # Skip if already seen
                    post_hash = hash(text[:100])
                    if post_hash in seen_posts:
                        continue
                    seen_posts.add(post_hash)
                    
                    # Get date
                    time_elem = await post.query_selector('time')
                    date_str = ""
                    if time_elem:
                        datetime_attr = await time_elem.get_attribute('datetime')
                        if datetime_attr:
                            date_str = datetime_attr
                    
                    # Parse post for signals
                    post_data = {
                        'date': date_str,
                        'text': text,
                        'tickers': [],
                        'signal_types': [],
                        'dollar_amounts': [],
                        'direction': None
                    }
                    
                    # Extract tickers (e.g., $SPY, $TSLA)
                    tickers = re.findall(r'\$[A-Z]{1,5}\b', text)
                    post_data['tickers'] = tickers
                    
                    # Extract signal types
                    signal_keywords = ['whale', 'sweep', 'gamma', 'flow', 'earnings', 'block', 'unusual']
                    for keyword in signal_keywords:
                        if keyword.lower() in text.lower():
                            post_data['signal_types'].append(keyword)
                    
                    # Extract dollar amounts
                    dollar_matches = re.findall(r'\$[\d,]+(?:\.\d+)?[MBK]?\b|\$[\d.]+[MBK]\b', text)
                    post_data['dollar_amounts'] = dollar_matches
                    
                    # Determine direction
                    if any(word in text.lower() for word in ['bullish', 'call', 'calls', 'buy', 'long']):
                        post_data['direction'] = 'bullish'
                    elif any(word in text.lower() for word in ['bearish', 'put', 'puts', 'sell', 'short']):
                        post_data['direction'] = 'bearish'
                    
                    # Only save posts with actionable signals
                    if post_data['tickers'] or post_data['signal_types'] or post_data['dollar_amounts']:
                        posts_data.append(post_data)
                        print(f"Post {len(posts_data)}: {date_str}")
                        print(f"  Tickers: {tickers}")
                        print(f"  Signals: {post_data['signal_types']}")
                        print(f"  Direction: {post_data['direction']}")
                        print(f"  Text preview: {text[:100]}...")
                
                except Exception as e:
                    print(f"Error processing post {i}: {e}")
                    continue
            
            # Scroll down
            await page.evaluate("window.scrollBy(0, 800)")
            await page.wait_for_timeout(2000)
            scroll_count += 1
        
        # Save data
        output_path = "/Users/nemotaka/clawd/cheddarflow_latest.json"
        with open(output_path, 'w', encoding='utf-8') as f:
            json.dump(posts_data, f, indent=2, ensure_ascii=False)
        
        print(f"\n\nTotal posts collected: {len(posts_data)}")
        print(f"Data saved to {output_path}")
        
        # Take final screenshot
        await page.screenshot(path="/Users/nemotaka/clawd/cheddarflow_final.png")
        print("Final screenshot saved")
        
        await browser.close()
        
        return posts_data

if __name__ == "__main__":
    asyncio.run(fetch_cheddarflow_posts())
