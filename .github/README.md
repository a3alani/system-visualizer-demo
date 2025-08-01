# GitHub Actions Workflows

This directory contains GitHub Actions workflows for automated system analysis and PR impact assessment.

## 🔄 Available Workflows

### 1. PR Analyzer (`pr-analyzer.yml`)

**Triggers**: Automatically runs on Pull Requests (opened, synchronized, reopened)

**What it does**:
- Analyzes code changes in the PR
- Generates impact diagrams showing affected components
- Posts comprehensive analysis as a PR comment
- Uploads generated diagrams as artifacts

**Features**:
- 🎯 **Smart targeting**: Only analyzes files in `app/` and `lib/` directories
- 📊 **Multiple diagram types**: PR impact, architecture overview, dependency analysis
- 🔄 **Comment updates**: Updates existing comments instead of creating new ones
- 📁 **Artifact storage**: Saves all diagrams with 30-day retention
- 🛡️ **Error resilience**: Continues even if some analysis steps fail

### 2. System Architecture Analysis (`system-analysis.yml`)

**Triggers**:
- 🕕 **Scheduled**: Every Monday at 6 AM UTC
- 🔘 **Manual**: Can be triggered manually via GitHub Actions UI
- 📝 **Push**: Runs on pushes to main/master branch

**What it does**:
- Performs comprehensive system analysis
- Generates all available diagram types
- Creates summary reports
- Archives analysis results for historical tracking

**Features**:
- 📅 **Regular monitoring**: Weekly automated analysis
- 🎛️ **Manual control**: On-demand analysis with configurable options
- 📦 **Long-term storage**: 90-day artifact retention
- 🏷️ **Release archiving**: Creates timestamped releases on main branch

## 🚀 How to Use

### For Pull Requests

1. **Automatic**: Simply create a PR - the analysis runs automatically
2. **Review**: Check the PR comment for impact analysis
3. **Artifacts**: Download detailed diagrams from the Actions tab

### For Manual Analysis

1. Go to **Actions** tab in your GitHub repository
2. Select **System Architecture Analysis** workflow
3. Click **Run workflow**
4. Choose analysis type (full/models-only/services-only/dependencies-only)
5. Review results in the workflow run

### For Scheduled Analysis

- Runs automatically every Monday at 6 AM UTC
- Results are archived for historical comparison
- Check Actions tab for weekly analysis reports

## 📊 Understanding the Output

### Diagram Types

| Diagram | Purpose | When to Review |
|---------|---------|----------------|
| **PR Impact** | Shows specific changes and their impact | Every PR review |
| **Architecture Overview** | High-level system structure | New team members, planning |
| **Dependency Analysis** | Component relationships and complexity | Refactoring, architecture reviews |
| **Circular Dependencies** | Identifies problematic dependencies | Code quality assessments |

### Color Coding

- 🔴 **Red**: High complexity/impact - needs attention
- 🟡 **Yellow**: Medium complexity/impact - monitor
- 🟢 **Green**: Low complexity/impact - healthy

### Reading the Diagrams

- **Solid arrows** → Direct dependencies
- **Dashed arrows** → Service/indirect dependencies
- **Grouped boxes** → Related components by domain
- **Numbers** → Dependency counts or action counts

## 🔧 Configuration

### Customizing Triggers

Edit the workflow files to change when they run:

```yaml
# Run on different events
on:
  pull_request:
    paths: ['app/**', 'custom/**']  # Different paths
  schedule:
    - cron: '0 9 * * 5'  # Friday at 9 AM instead
```

### Adjusting Retention

Change artifact retention periods:

```yaml
# Longer retention for important analyses
retention-days: 180  # Keep for 6 months
```

### Adding Notifications

Add Slack/email notifications:

```yaml
- name: Notify team
  if: failure()
  uses: your-notification-action
```

## 🛠️ Troubleshooting

### Common Issues

1. **No diagrams generated**
   - Check if `app/` directory exists and contains Ruby files
   - Verify the SystemVisualizer can find models/controllers/services

2. **Permission errors**
   - Ensure the workflow has `pull-requests: write` permission
   - Check if the repository allows Actions to comment on PRs

3. **Analysis fails**
   - Review the workflow logs in the Actions tab
   - Check if there are syntax errors in Ruby files

### Getting Help

- Check workflow logs in Actions tab
- Review error messages in PR comments
- Verify file paths match your project structure

## 🎯 Best Practices

1. **Review generated diagrams** before merging PRs
2. **Use artifact downloads** for detailed analysis
3. **Monitor weekly reports** for architecture drift
4. **Update paths** in workflows if you change project structure
5. **Archive important analyses** for future reference

---

_Generated documentation for System Visualizer GitHub Actions workflows_ 