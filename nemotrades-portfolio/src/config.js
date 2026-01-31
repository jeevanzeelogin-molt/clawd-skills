// Portfolio Configuration - Nemotrades
const PORTFOLIO = {
  id: 'rZrUg05YbafekL0CYxAs',
  url: 'https://optionomega.com/portfolio/rZrUg05YbafekL0CYxAs',
  baseline: {
    mar: 192,
    mdd: 18,
    cagr: 48.5,
    capital: 237440,
    startCapital: 160000,
    profit: 77440
  },
  target: {
    mar: 250,
    mdd: 15,
    cagr: 55
  }
};

// Strategy Database - 19 strategies with current parameters
const STRATEGIES = [
  {
    id: 1,
    name: "Overnight Diagonal",
    currentAllocation: 7.00,
    type: "RIC",
    dte: "0DTE",
    entryTime: "3:00 PM",
    days: ["Mon", "Tue", "Wed", "Fri"],
    baselineMAR: 8.5,
    status: "active",
    improvementAreas: ["position_sizing", "exit_timing"]
  },
  {
    id: 2,
    name: "BWB Gap Down - Max 3 Open",
    currentAllocation: 6.21,
    type: "RIC",
    dte: "45DTE",
    entryTime: "9:32 AM",
    filter: "Gap Down > 0.4%",
    baselineMAR: 9.2,
    status: "active",
    improvementAreas: ["gap_threshold", "profit_target"]
  },
  {
    id: 3,
    name: "A New 9/23 mod2",
    currentAllocation: 3.78,
    type: "Multi-leg",
    dte: "9DTE/23DTE",
    entryTime: "9:35-11:30 AM",
    filter: "RSI > 60",
    baselineMAR: 12.4,
    status: "star_performer",
    improvementAreas: ["scale_up"]
  },
  {
    id: 4,
    name: "Ric Intraday swan net",
    currentAllocation: 3.24,
    type: "RIC",
    dte: "0DTE",
    entryTime: "10:30-12:30 PM",
    filter: "VIX Down > 1%",
    baselineMAR: 7.8,
    status: "active",
    improvementAreas: ["vix_filter"]
  },
  {
    id: 5,
    name: "EOM only Straddle",
    currentAllocation: 3.00,
    type: "Straddle",
    dte: "0DTE",
    entryTime: "9:32 AM - 1:30 PM",
    maxPremium: 35,
    baselineMAR: 15.2,
    status: "star_performer",
    improvementAreas: ["scale_up", "premium_optimization"]
  },
  {
    id: 6,
    name: "Dan 11/14 - mon",
    currentAllocation: 2.70,
    type: "RIC",
    dte: "11DTE/15DTE",
    entryTime: "2:59 PM",
    days: ["Mon"],
    baselineMAR: 10.1,
    status: "active",
    improvementAreas: ["entry_timing"]
  },
  {
    id: 7,
    name: "New JonE 42 Delta",
    currentAllocation: 2.52,
    type: "Multi-leg",
    dte: "5DTE",
    entryTime: "10:15-2:30 PM",
    filter: "RSI 55-70, Move 0.25-0.4%",
    baselineMAR: 6.5,
    status: "underperformer",
    improvementAreas: ["parameter_optimization", "rsi_range"]
  },
  {
    id: 8,
    name: "R3. Jeevan Vix DOWN Straddle",
    currentAllocation: 2.00,
    type: "Straddle",
    dte: "0DTE",
    entryTime: "9:32 AM - 1:30 PM",
    maxPremium: 32,
    filter: "VIX Down, Max Gap 0.9%",
    baselineMAR: 11.8,
    status: "active",
    improvementAreas: ["scale_up"]
  },
  {
    id: 9,
    name: "1:45 Iron Condor Without EOM",
    currentAllocation: 1.80,
    type: "Iron Condor",
    dte: "0DTE",
    entryTime: "1:45 PM",
    filter: "VIX > 14, 2D SMA > 4D SMA",
    baselineMAR: 18.5,
    status: "top_performer",
    improvementAreas: ["scale_up_significantly"]
  },
  {
    id: 10,
    name: "monday 2/4 dc",
    currentAllocation: 1.71,
    type: "RIC",
    dte: "2DTE/4DTE",
    entryTime: "2:30 PM",
    days: ["Mon"],
    baselineMAR: 8.2,
    status: "active",
    improvementAreas: []
  },
  {
    id: 11,
    name: "fri 6/7",
    currentAllocation: 1.62,
    type: "RIC",
    dte: "6DTE/7DTE",
    entryTime: "12:45 PM",
    days: ["Fri"],
    baselineMAR: 7.5,
    status: "active",
    improvementAreas: []
  },
  {
    id: 12,
    name: "move down 0 dte ic",
    currentAllocation: 1.62,
    type: "Iron Condor",
    dte: "0DTE",
    entryTime: "11:00-11:30 AM",
    filter: "VIX Down, RSI 55-70",
    baselineMAR: 9.8,
    status: "active",
    improvementAreas: []
  },
  {
    id: 13,
    name: "10 day RiC - 2",
    currentAllocation: 1.32,
    type: "RIC",
    dte: "10DTE",
    entryTime: "12:45 PM",
    days: ["Wed"],
    filter: "RSI < 60",
    baselineMAR: 4.2,
    status: "underperformer",
    improvementAreas: ["parameter_review", "dte_adjustment"]
  },
  {
    id: 14,
    name: "R3. Mr. Tea's RIC",
    currentAllocation: 1.44,
    type: "RIC",
    dte: "0DTE",
    entryTime: "10:30-12:30 PM",
    filter: "VIX Down > 1%",
    baselineMAR: 8.8,
    status: "active",
    improvementAreas: []
  },
  {
    id: 15,
    name: "put with cs",
    currentAllocation: 2.34,
    type: "Multi-leg",
    dte: "0DTE",
    entryTime: "9:32 AM - 12:30 PM",
    baselineMAR: 9.5,
    status: "active",
    improvementAreas: []
  },
  {
    id: 16,
    name: "R6. MOC straddle/EOD",
    currentAllocation: 1.89,
    type: "Straddle",
    dte: "0DTE",
    entryTime: "3:48 PM",
    baselineMAR: 10.5,
    status: "active",
    improvementAreas: ["scale_up"]
  },
  {
    id: 17,
    name: "McRib Deluxe",
    currentAllocation: 0.81,
    type: "RIC",
    dte: "0DTE",
    entryTime: "9:40-11:20 AM",
    filter: "VIX Down, RSI > 40",
    baselineMAR: 14.2,
    status: "hidden_gem",
    improvementAreas: ["scale_up_significantly"]
  },
  {
    id: 18,
    name: "R2. EOM 3:45pm Strangle",
    currentAllocation: 2.88,
    type: "Strangle",
    dte: "0DTE",
    entryTime: "3:45 PM",
    maxCap: 1000,
    baselineMAR: 11.5,
    status: "active",
    improvementAreas: ["scale_up"]
  },
  {
    id: 19,
    name: "EOM only Straddle $35",
    currentAllocation: 3.00,
    type: "Straddle",
    dte: "0DTE",
    entryTime: "9:32 AM - 1:30 PM",
    maxPremium: 35,
    baselineMAR: 16.8,
    status: "star_performer",
    improvementAreas: ["scale_up"]
  }
];

// Export for use in other modules
module.exports = { PORTFOLIO, STRATEGIES };
