#!/usr/bin/env ruby

puts "🚀 Enhanced System Visualizer Demo"
puts "=" * 60

# Load the enhanced system visualizer
require_relative 'lib/system_visualizer'

# Demo scenarios with enhanced risk factors
demos = [
  {
    name: "🔒 High-Risk Authentication System Changes",
    files: [
      "app/models/user.rb", 
      "app/controllers/sessions_controller.rb", 
      "app/models/authentication.rb",
      "app/services/auth_service.rb"
    ],
    impact: "Critical",
    dependencies: ["User", "Session", "Authentication", "Firm", "AuthService"],
    security_risks: ["Authentication bypass", "Session hijacking potential"],
    performance_risks: ["N+1 queries in user lookup", "Expensive password hashing"],
    database_impacts: ["New indexes needed for session lookups"],
    ai_risk_score: 85
  },
  {
    name: "💳 Medium-Risk Payment Processing Updates", 
    files: [
      "app/models/payment.rb", 
      "app/controllers/payments_controller.rb", 
      "app/services/payment_service.rb",
      "app/workers/payment_processor.rb"
    ],
    impact: "High",
    dependencies: ["Payment", "User", "PaymentService", "LawPay", "PaymentProcessor"],
    security_risks: ["PCI compliance check needed"],
    performance_risks: ["Synchronous payment processing"],
    database_impacts: ["Payment audit logs storage"],
    ai_risk_score: 65
  },
  {
    name: "📄 Low-Risk Document Management Feature",
    files: [
      "app/models/document.rb", 
      "app/workers/document_processor.rb",
      "spec/models/document_spec.rb"
    ],
    impact: "Medium", 
    dependencies: ["Document", "User", "DocumentProcessor"],
    security_risks: [],
    performance_risks: ["Large file processing"],
    database_impacts: ["Document metadata indexing"],
    ai_risk_score: 35
  },
  {
    name: "🧪 Test Infrastructure Improvements",
    files: [
      "spec/factories/users.rb",
      "spec/support/auth_helpers.rb", 
      "test/test_helper.rb"
    ],
    impact: "Low",
    dependencies: ["TestFactories", "AuthHelpers"],
    security_risks: [],
    performance_risks: [],
    database_impacts: [],
    ai_risk_score: 15
  }
]

def generate_enhanced_mermaid_for_demo(demo)
  mermaid = "graph TD\n"
  
  # Add AI Risk Score prominently
  risk_class = case demo[:ai_risk_score]
               when 80..100 then "criticalRisk"
               when 60..79 then "highRisk"
               when 30..59 then "mediumRisk"
               else "lowRisk"
               end
  
  mermaid += "  AIRisk[\"🤖 AI Risk Score: #{demo[:ai_risk_score]}/100<br/>Level: #{get_risk_level(demo[:ai_risk_score])}\"]:::#{risk_class}\n"
  
  # Add changed files with enhanced impact styling
  demo[:files].each_with_index do |file, i|
    component = file.split('/').last.gsub('.rb', '').split('_').map(&:capitalize).join
    impact_emoji = case demo[:impact]
                   when "Critical" then "🔴"
                   when "High" then "🟠"
                   when "Medium" then "🟡"
                   else "🟢"
                   end
    
    mermaid += "  #{component}[\"#{impact_emoji} #{component}<br/>#{file}<br/>Impact: #{demo[:impact]}\"]\n"
    mermaid += "  #{component} --> AIRisk\n"
  end
  
  # Add risk categories
  if demo[:security_risks].any?
    mermaid += "  SecurityRisks[\"🔒 Security Risks<br/>#{demo[:security_risks].join('<br/>')}\"]:::securityRisk\n"
    mermaid += "  AIRisk --> SecurityRisks\n"
  end
  
  if demo[:performance_risks].any?
    mermaid += "  PerformanceRisks[\"⚡ Performance Risks<br/>#{demo[:performance_risks].join('<br/>')}\"]:::performanceRisk\n"
    mermaid += "  AIRisk --> PerformanceRisks\n"
  end
  
  if demo[:database_impacts].any?
    mermaid += "  DatabaseImpacts[\"🗄️ Database Impacts<br/>#{demo[:database_impacts].join('<br/>')}\"]:::databaseImpact\n"
    mermaid += "  AIRisk --> DatabaseImpacts\n"
  end
  
  # Add dependencies with complexity indicators
  demo[:dependencies].each_with_index do |dep, i|
    complexity = rand(1..20)  # Simulate complexity
    complexity_class = if complexity > 15
                        "highComplexity"
                      elsif complexity > 8
                        "mediumComplexity"
                      else
                        "lowComplexity"
                      end
    
    mermaid += "  #{dep}[\"#{dep}<br/>Complexity: #{complexity}\"]:::#{complexity_class}\n"
    mermaid += "  AIRisk --> #{dep}\n"
  end
  
  # Enhanced styling
  mermaid += "\n  classDef criticalRisk fill:#cc0000,stroke:#990000,stroke-width:3px,color:#ffffff\n"
  mermaid += "  classDef highRisk fill:#ff3333,stroke:#cc0000,stroke-width:2px\n"
  mermaid += "  classDef mediumRisk fill:#ffaa66,stroke:#cc6600,stroke-width:2px\n"
  mermaid += "  classDef lowRisk fill:#66ff66,stroke:#00cc00,stroke-width:2px\n"
  mermaid += "  classDef securityRisk fill:#ff6b6b,stroke:#d63031,stroke-width:2px\n"
  mermaid += "  classDef performanceRisk fill:#fdcb6e,stroke:#e17055,stroke-width:2px\n"
  mermaid += "  classDef databaseImpact fill:#74b9ff,stroke:#0984e3,stroke-width:2px\n"
  mermaid += "  classDef highComplexity fill:#ffcccc,stroke:#ff6666,stroke-width:2px\n"
  mermaid += "  classDef mediumComplexity fill:#ffffcc,stroke:#ffaa66,stroke-width:2px\n"
  mermaid += "  classDef lowComplexity fill:#ccffcc,stroke:#66ff66,stroke-width:2px\n"
  
  mermaid
end

def get_risk_level(score)
  case score
  when 80..100 then "Critical"
  when 60..79 then "High"
  when 30..59 then "Medium"
  else "Low"
  end
end

def generate_risk_summary(demo)
  summary = "\n🔍 Enhanced Analysis Results:\n"
  summary += "  • AI Risk Score: #{demo[:ai_risk_score]}/100 (#{get_risk_level(demo[:ai_risk_score])})\n"
  summary += "  • Security Risks: #{demo[:security_risks].size}\n"
  summary += "  • Performance Risks: #{demo[:performance_risks].size}\n"
  summary += "  • Database Impacts: #{demo[:database_impacts].size}\n"
  summary += "  • Dependencies Affected: #{demo[:dependencies].size}\n"
  
  if demo[:ai_risk_score] > 70
    summary += "\n💡 AI Recommendations:\n"
    summary += "  • Consider breaking this PR into smaller chunks\n"
    summary += "  • Require additional security review\n"
    summary += "  • Add comprehensive integration tests\n"
  elsif demo[:ai_risk_score] > 40
    summary += "\n💡 AI Recommendations:\n"
    summary += "  • Standard code review process\n"
    summary += "  • Verify test coverage for changed areas\n"
  else
    summary += "\n💡 AI Recommendations:\n"
    summary += "  • Low risk - routine review sufficient\n"
  end
  
  summary
end

# Demo each scenario with enhanced features
demos.each_with_index do |demo, i|
  puts "\n#{i + 1}. 🎯 Analyzing: #{demo[:name]}"
  puts "-" * 50
  puts "Files changed: #{demo[:files].join(', ')}"
  puts "Traditional impact level: #{demo[:impact]}"
  puts generate_risk_summary(demo)
  
  puts "\n📊 Enhanced Mermaid Diagram with AI Analysis:"
  puts "```mermaid"
  puts generate_enhanced_mermaid_for_demo(demo)
  puts "```"
  puts "\n" + "=" * 60
end

# Showcase export formats
puts "\n🚀 NEW ENHANCED FEATURES DEMO:"
puts "-" * 40

puts "\n1. 📤 Multiple Export Formats Available:"
puts "   • HTML Reports with interactive styling"
puts "   • JSON API for programmatic access"  
puts "   • GitHub-ready comment formatting"
puts "   • PDF generation (via HTML)"

puts "\n2. 🤖 AI-Powered Risk Analysis:"
puts "   • Intelligent risk scoring (0-100)"
puts "   • Multi-factor risk assessment"
puts "   • Automated recommendations"
puts "   • Pattern recognition for common issues"

puts "\n3. 🔒 Advanced Security Detection:"
puts "   • SQL injection vulnerability scanning"
puts "   • Authentication bypass detection"
puts "   • Mass assignment vulnerability checks"
puts "   • XSS vulnerability identification"

puts "\n4. ⚡ Performance Impact Analysis:"
puts "   • N+1 query detection"
puts "   • Heavy operation identification"
puts "   • Missing index recommendations"
puts "   • Query optimization suggestions"

puts "\n5. 🗄️ Database Impact Assessment:"
puts "   • Schema change detection"
puts "   • Migration impact analysis"
puts "   • Index recommendation system"
puts "   • Data operation risk assessment"

puts "\n6. 🧪 Test Coverage Analysis:"
puts "   • Missing test file detection"
puts "   • Factory coverage analysis"
puts "   • Test complexity scoring"
puts "   • Coverage gap identification"

puts "\n🎉 Demo complete! To try these features:"
puts "\n📋 Available CLI Commands:"
puts "   bin/system_visualizer analyze              # Full enhanced analysis"
puts "   bin/system_visualizer pr main              # Enhanced PR analysis"
puts "   bin/system_visualizer risk-assessment      # Security & performance focus"
puts "   bin/system_visualizer export html          # Export as interactive HTML"
puts "   bin/system_visualizer test-coverage        # Test coverage analysis"
puts "   bin/system_visualizer complexity           # Complexity analysis"

puts "\n💡 For your hackathon presentation:"
puts "   1. Run: bin/system_visualizer pr main"
puts "   2. Open: docs/system-diagrams/reports/pr_analysis_report.html"
puts "   3. Show the AI risk scoring and visual diagrams"
puts "   4. Demonstrate GitHub integration with auto-comments"
puts "   5. Highlight the comprehensive risk assessment"

puts "\n🌟 Key Selling Points:"
puts "   • AI-powered analysis beyond simple pattern matching"
puts "   • Multiple export formats for different audiences"
puts "   • Comprehensive security and performance insights"
puts "   • Ready for CI/CD integration"
puts "   • Beautiful, interactive reports"
puts "   • Zero configuration required"

puts "\n🚀 Ready to revolutionize code review processes!"
