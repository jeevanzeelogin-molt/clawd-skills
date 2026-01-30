# Clawd Skills Collection

A curated collection of AI agent skills for the Clawdbot platform.

## 📚 Skill Catalog

### 🔄 Automation & Scheduling
| Skill | Description | Status |
|-------|-------------|--------|
| **nemoblock-scheduler** | Manage Launchd jobs for Nemoblock trading analytics | ✅ Active |
| **ai-compound** | Auto-review sessions, extract learnings, compound knowledge | ✅ Active |
| **compound-engineering** | Automated learning and improvement system | ✅ Active |

### 💰 Finance & Trading
| Skill | Description | Status |
|-------|-------------|--------|
| **stock-market-pro** | Stock prices, valuation metrics, earnings, charts | ✅ Active |
| **yahoo-finance** | Yahoo Finance data - quotes, fundamentals, options | ✅ Active |
| **cost-report** | Track Clawdbot AI usage and estimate costs | ✅ Active |

### 🔍 Research & Search
| Skill | Description | Status |
|-------|-------------|--------|
| **exa-web-search-free** | Web search using Exa API | ✅ Active |
| **answeroverflow** | Search indexed Discord community discussions | ✅ Active |
| **twitter-search** | Twitter/X search and social media analysis | ✅ Active |
| **find-skills** | Discover and install new agent skills | ✅ Active |

### 📝 Content & Media
| Skill | Description | Status |
|-------|-------------|--------|
| **youtube-transcript** | Fetch and summarize YouTube video transcripts | ✅ Active |
| **youtube** | YouTube video operations | ✅ Active |
| **youtube-watcher** | Monitor YouTube channels and videos | ✅ Active |

### 🛠️ Development & Tools
| Skill | Description | Status |
|-------|-------------|--------|
| **git-essentials** | Essential Git commands and workflows | ✅ Active |
| **github** | GitHub CLI integration (gh) | ✅ Active |
| **playwright-cli** | Browser automation with Playwright | ✅ Active |
| **prompt-engineering-expert** | Advanced prompt engineering and optimization | ✅ Active |
| **superdesign** | Frontend design guidelines for modern UIs | ✅ Active |
| **clawddocs** | Clawdbot documentation expert | ✅ Active |

### 🔐 Security & Monitoring
| Skill | Description | Status |
|-------|-------------|--------|
| **clawdbot-security-check** | Security audit of Clawdbot configuration | ✅ Active |
| **dont-hack-me** | Quick security self-check | ✅ Active |

### 🧠 Knowledge Management
| Skill | Description | Status |
|-------|-------------|--------|
| **byterover** | Project knowledge using ByteRover context tree | ✅ Active |
| **second-brain** | Personal knowledge management | ✅ Active |
| **moltbot-best-practices** | Best practices for AI agents | ✅ Active |

### 🌐 Network & Infrastructure
| Skill | Description | Status |
|-------|-------------|--------|
| **tailscale** | Manage Tailscale network | ✅ Active |

## 🚀 Quick Start

### Using a Skill

```bash
# List all available skills
ls skills/

# Read a skill's documentation
cat skills/nemoblock-scheduler/SKILL.md
```

### Adding a New Skill

1. Create skill directory: `mkdir skills/my-new-skill`
2. Add SKILL.md with frontmatter and instructions
3. Add any scripts/references/assets
4. Commit and push

## 📁 Repository Structure

```
clawd/
├── skills/              # All skills live here
│   ├── skill-name/
│   │   ├── SKILL.md     # Required: skill documentation
│   │   ├── scripts/     # Optional: helper scripts
│   │   ├── references/  # Optional: reference docs
│   │   └── assets/      # Optional: templates, images
│   └── ...
├── README.md            # This file
└── ...
```

## 🔧 Installation

To use these skills with Clawdbot:

1. Clone this repo
2. Skills are automatically loaded from the `skills/` directory
3. Reference skills by name when needed

## 📝 Contributing

When adding new skills:
- Follow the skill naming convention: `lowercase-with-hyphens`
- Include proper frontmatter in SKILL.md
- Test scripts before committing
- Update this README with the new skill

## 📊 Stats

- **Total Skills:** 29
- **Categories:** 8
- **Last Updated:** 2026-01-29

---

*Built for the Clawdbot ecosystem*
