import asyncio
import json
import re
from datetime import datetime, timedelta
from playwright.async_api import async_playwright

async def fetch_cheddarflow_posts():
    posts_data = []
    
    async with async_playwright() as p:
        # Connect to the existing browser via CDP
        browser = await p.chromium.connect_over_cdp("http://127.0.0.1:18800")
        
        # Use existing context if available, otherwise create new
        contexts = browser.contexts
        if contexts:
            context = contexts[0]
            print(f"Using existing context with {len(context.pages)} pages")
        else:
            context = await browser.new_context(viewport={"width": 1920, "height": 1080})
            print("Created new context")
        
        # Get or create page
        if context.pages:
            page = context.pages[0]
            print("Using existing page")
        else:
            page = await context.new_page()
            print("Created new page")
        
        print("Navigating to CheddarFlow X page...")
        await page.goto("https://x.com/CheddarFlow", wait_until="domcontentloaded")
        
        # Wait for page to load - X takes time
        print("Waiting for page to fully load...")
        await page.wait_for_timeout(10000)
        
        # Try to wait for tweets to appear
        try:
            await page.wait_for_selector('article[data-testid="tweet"]', timeout=30000)
            print("Tweets found on page")
        except:
            print("Could not find tweets, taking screenshot to debug")
            await page.screenshot(path="/Users/nemotaka/clawd/cheddarflow_debug.png")
        
        # Take screenshot
        await page.screenshot(path="/Users/nemotaka/clawd/cheddarflow_current.png")
        print("Screenshot saved")
        
        # Get page content for debugging
        content = await page.content()
        print(f"Page content length: {len(content)}")
        
        # Scroll and collect posts
        scroll_count = 0
        max_scrolls = 150
        seen_posts = set()
        
        while scroll_count < max_scrolls:
            print(f"\n--- Scroll {scroll_count + 1}/{max_scrolls} ---")
            
            # Get all visible posts
            posts = await page.query_selector_all('article[data-testid="tweet"]')
            print(f"Found {len(posts)} posts on screen")
            
            new_posts_found = 0
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
                    new_posts_found += 1
                    
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
                    signal_keywords = ['whale', 'sweep', 'gamma', 'flow', 'earnings', 'block', 'unusual', 'dark pool']
                    for keyword in signal_keywords:
                        if keyword.lower() in text.lower():
                            post_data['signal_types'].append(keyword)
                    
                    # Extract dollar amounts
                    dollar_matches = re.findall(r'\$[\d,]+(?:\.\d+)?[MBK]?\b|\$[\d.]+[MBK]\b', text)
                    post_data['dollar_amounts'] = dollar_matches
                    
                    # Determine direction
                    if any(word in text.lower() for word in ['bullish', 'call', 'calls', 'buy', 'long', 'over']):
                        post_data['direction'] = 'bullish'
                    elif any(word in text.lower() for word in ['bearish', 'put', 'puts', 'sell', 'short', 'under']):
                        post_data['direction'] = 'bearish'
                    
                    # Only save posts with actionable signals
                    if post_data['tickers'] or post_data['signal_types'] or post_data['dollar_amounts']:
                        posts_data.append(post_data)
                        print(f"Post {len(posts_data)}: {date_str}")
                        print(f"  Tickers: {tickers}")
                        print(f"  Signals: {post_data['signal_types']}")
                        print(f"  Direction: {post_data['direction']}")
                        print(f"  Text: {text[:80]}...")
                
                except Exception as e:
                    print(f"Error processing post {i}: {e}")
                    continue
            
            print(f"New posts this scroll: {new_posts_found}")
            
            # Check if we should stop based on date
            if posts_data:
                try:
                    latest_dates = [p['date'] for p in posts_data[-10:] if p['date']]
                    if latest_dates:
                        for date_str in latest_dates:
                            try:
                                post_date = datetime.fromisoformat(date_str.replace('Z', '+00:00'))
                                if post_date < datetime(2025, 8, 1, tzinfo=post_date.tzinfo):
                                    print(f"Reached posts from {post_date.strftime('%B %Y')}. Stopping.")
                                    scroll_count = max_scrolls  # Force exit
                                    break
                            except:
                                continue
                except Exception as e:
                    print(f"Date check error: {e}")
            
            # Scroll down
            await page.evaluate("window.scrollBy(0, 1000)")
            await page.wait_for_timeout(2500)
            scroll_count += 1
        
        # Save data
        output_path = "/Users/nemotaka/clawd/cheddarflow_6mo_complete.json"
        with open(output_path, 'w', encoding='utf-8') as f:
            json.dump(posts_data, f, indent=2, ensure_ascii=False)
        
        print(f"\n\n{'='*50}")
        print(f"Total posts collected: {len(posts_data)}")
        print(f"Data saved to {output_path}")
        print(f"{'='*50}")
        
        await browser.close()

if __name__ == "__main__":
    asyncio.run(fetch_cheddarflow_posts())
