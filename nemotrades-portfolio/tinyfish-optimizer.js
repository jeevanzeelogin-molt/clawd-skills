#!/usr/bin/env node
/**
 * TinyFish Agent - Option Omega Portfolio Optimizer
 * 
 * Creates Nemo_Optimized_2026 portfolio with optimized allocations
 * Target: Beat MAR 209.4, MDD ≤ 18.1%
 */

import { TinyFish } from '@tinyfish/agent';
import dotenv from 'dotenv';

dotenv.config({ path: '/Users/nemotaka/.clawdbot/.env' });

const TINYFISH_API_KEY = process.env.TINYFISH_API_KEY;

if (!TINYFISH_API_KEY) {
  console.error('❌ TINYFISH_API_KEY not found in environment');
  process.exit(1);
}

const tinyfish = new TinyFish({ apiKey: TINYFISH_API_KEY });

// Optimized allocation strategy
const OPTIMIZED_ALLOCATIONS = {
  '10 day RiC - 2': 0,                    // ELIMINATE
  'A New 9/23 mod2': 2.5,                 // Reduced from 3.3%
  'BWB Gap Down - Max 3 Open': 6,         // Slight reduce from 6.21%
  'Dan 11/14 - mon': 2,                   // Slight reduce from 2.2%
  '1:45 Iron Condor Without EOM': 6,      // INCREASE from 4%
  'EOM Straddle $35 limit': 5,            // INCREASE from 3.1%
  'McRib Deluxe': 3,                      // MASSIVE INCREASE from 0.8%
  'New JonE 42 Delta - 1 con': 1.5,       // SLASH from 4%
  'ORB Breakout BF 30/30/30': 1,          // Keep same
  'Overnight Diagonal': 12,               // INCREASE from 10%
  'R2. EOM 3:45pm Strangle 2.0': 0,      // ELIMINATE
  'R3. Jeevan Vix DOWN Straddle': 3,      // INCREASE from 2%
  'R6. MOC straddle/EOD last 12 min': 2,  // Slight increase from 1.89%
  'Ric Intraday swan net': 2,             // INCREASE from 1.2%
  'VIX UP 9:35 Iron Condor': 0.5,         // Slight reduce from 0.6%
  'fri 6/7': 1.5,                         // Slight increase from 1.4%
  'monday 2/4 dc': 1,                     // Reduce from 1.6%
  'move down 0 dte ic - less risk': 2,    // Reduce from 3%
  'put with cs': 0.5                      // Reduce from 1.2%
};

async function createOptimizedPortfolio() {
  console.log('🚀 Starting Option Omega Portfolio Optimization');
  console.log('==============================================');
  console.log('Target: MAR 245-255 (up from 209.4)');
  console.log('MDD: ≤ 18.1%');
  console.log('');

  try {
    const result = await tinyfish.run({
      name: 'Option Omega Portfolio Creation',
      url: 'https://optionomega.com/portfolio/rZrUg05YbafekL0CYxAs',
      
      steps: [
        // Step 1: Navigate and login if needed
        {
          action: 'navigate',
          url: 'https://optionomega.com/portfolio/rZrUg05YbafekL0CYxAs',
          description: 'Navigate to baseline portfolio'
        },
        
        // Step 2: Click New Portfolio
        {
          action: 'click',
          element: 'button with text "New Portfolio"',
          description: 'Click New Portfolio button'
        },
        
        // Step 3: Set starting funds and dates
        {
          action: 'fill',
          fields: [
            { selector: 'Starting Funds input', value: '160000' },
            { selector: 'Start Date input', value: '05/16/2022' },
            { selector: 'End Date input', value: '01/29/2026' }
          ],
          description: 'Set portfolio parameters'
        },
        
        // Step 4: Select strategies and set allocations
        {
          action: 'custom',
          description: 'Select all 19 strategies with optimized allocations',
          script: `
            const allocations = ${JSON.stringify(OPTIMIZED_ALLOCATIONS)};
            
            // For each strategy in the list
            Object.entries(allocations).forEach(([strategyName, alloc]) => {
              // Find the row
              const row = document.querySelector(
                'tr:has(td:nth-child(2):contains("' + strategyName + '"))'
              );
              
              if (row) {
                // Check the checkbox if allocation > 0
                if (alloc > 0) {
                  const checkbox = row.querySelector('input[type="checkbox"]');
                  if (checkbox && !checkbox.checked) {
                    checkbox.click();
                  }
                  
                  // Set allocation
                  const allocInput = row.querySelector('td:nth-child(8) input');
                  if (allocInput) {
                    allocInput.value = alloc;
                    allocInput.dispatchEvent(new Event('input', { bubbles: true }));
                  }
                }
              }
            });
          `
        },
        
        // Step 5: Run the portfolio
        {
          action: 'click',
          element: 'button with text "Run"',
          description: 'Run portfolio backtest',
          waitAfter: 60000  // Wait 60 seconds for backtest
        },
        
        // Step 6: Extract results
        {
          action: 'extract',
          fields: {
            mar: 'MAR Ratio value',
            mdd: 'Max Drawdown value',
            cagr: 'CAGR value',
            pl: 'P/L value'
          },
          description: 'Extract portfolio metrics'
        },
        
        // Step 7: Save if results are good
        {
          action: 'click',
          element: 'save button or icon',
          description: 'Save portfolio',
          condition: 'if MAR > 209.4'
        },
        
        // Step 8: Name the portfolio
        {
          action: 'fill',
          fields: [
            { selector: 'Portfolio Name input', value: 'Nemo_Optimized_2026' }
          ],
          description: 'Name the new portfolio'
        }
      ]
    });

    console.log('✅ Portfolio creation completed!');
    console.log('Results:', result);
    
    // Verify results
    if (result.mar > 209.4 && result.mdd <= 18.1) {
      console.log('🎉 CHALLENGE COMPLETE!');
      console.log(`MAR improved: 209.4 → ${result.mar}`);
      console.log(`MDD: ${result.mdd}`);
    } else {
      console.log('⚠️ Results did not beat baseline');
      console.log(`MAR: ${result.mar} (target > 209.4)`);
      console.log(`MDD: ${result.mdd} (target ≤ 18.1)`);
    }
    
    return result;
    
  } catch (error) {
    console.error('❌ Error:', error.message);
    throw error;
  }
}

// Run the optimizer
createOptimizedPortfolio()
  .then(result => {
    console.log('\n📊 Final Report:');
    console.log(JSON.stringify(result, null, 2));
    process.exit(0);
  })
  .catch(error => {
    console.error('\n💥 Failed:', error);
    process.exit(1);
  });
