# System Visualizer Demo

A demonstration of the System Visualizer tool that analyzes Rails codebases and generates dependency diagrams.

## 🎯 What This Demo Shows

This repository demonstrates how the System Visualizer can:
- **Analyze Rails-like codebases** and extract dependencies
- **Generate detailed diagrams** showing relationships between components
- **Provide PR impact analysis** for code reviews
- **Identify high-risk areas** and circular dependencies

## 📊 Generated Diagrams

The following diagrams are automatically generated:

### **Overview Diagrams**
- `overview.md` - High-level architecture overview
- `models.md` - Model relationships and dependencies
- `controllers.md` - Controller actions and dependencies
- `services.md` - Service layer dependencies
- `workers.md` - Background job dependencies

### **Analysis Diagrams**
- `dependency-analysis.md` - Most referenced models and complex components
- `service-dependency-map.md` - Service layer dependency mapping
- `circular-dependency-analysis.md` - Circular dependency detection
- `pr-changes.md` - PR impact analysis

## 🚀 How to Test

### **1. Local Analysis**
```bash
# Analyze the entire codebase
bin/system_visualizer analyze

# Analyze PR changes (compare with master)
bin/system_visualizer pr master
```

### **2. GitHub Integration**
1. Push this repository to GitHub
2. Create a Pull Request
3. The GitHub Action will automatically:
   - Analyze the PR changes
   - Post a comment with the impact diagram
   - Upload diagrams as artifacts

### **3. View Diagrams**
- Copy the Mermaid code from any `.md` file
- Paste into [Mermaid Live Editor](https://mermaid.live/)
- Or use GitHub's built-in Mermaid support

## 📁 Sample Code Structure

This demo includes sample Rails-like files:

```
app/
├── models/
│   ├── user.rb          # User model with associations
│   ├── firm.rb          # Firm model
│   └── document.rb      # Document model
├── controllers/
│   └── users_controller.rb  # Users controller with actions
├── services/
│   └── user_service.rb      # User business logic service
└── workers/
    └── email_worker.rb      # Background email worker
```

## 🔧 Customization

To test with your own code:

1. **Replace sample files** with your actual Rails code
2. **Modify the analyzer** in `lib/system_visualizer.rb`
3. **Update GitHub Actions** in `.github/workflows/system-visualizer.yml`

## 🎨 Diagram Features

- **Color-coded complexity**: Red (high), Yellow (medium), Green (low)
- **Dependency counts**: Shows how many components depend on each other
- **Impact analysis**: Identifies high-risk changes
- **Domain grouping**: Groups components by functionality
- **Relationship mapping**: Shows actual dependencies between components

## 📈 Use Cases

- **Code Reviews**: Understand the impact of changes
- **Architecture Analysis**: Identify complex areas needing refactoring
- **Onboarding**: Help new engineers understand the codebase
- **Risk Assessment**: Identify high-risk changes before deployment

## 🤝 Contributing

This is a demo repository. Feel free to:
- Fork and modify for your own testing
- Submit issues or suggestions
- Create PRs to improve the demo

## 📄 License

MIT License - feel free to use this demo for your own projects! 