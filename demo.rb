#!/usr/bin/env ruby

puts "🔍 System Visualizer Demo"
puts "=" * 50

# Simulate analyzing different types of changes
demos = [
  {
    name: "Authentication System Changes",
    files: ["app/models/user.rb", "app/controllers/sessions_controller.rb", "app/models/authentication.rb"],
    impact: "High",
    dependencies: ["User", "Session", "Authentication", "Firm"]
  },
  {
    name: "Payment Processing Updates", 
    files: ["app/models/payment.rb", "app/controllers/payments_controller.rb", "app/services/payment_service.rb"],
    impact: "Medium",
    dependencies: ["Payment", "User", "PaymentService", "LawPay"]
  },
  {
    name: "Document Management Feature",
    files: ["app/models/document.rb", "app/workers/document_processor.rb"],
    impact: "Low", 
    dependencies: ["Document", "User", "DocumentProcessor"]
  }
]

def generate_mermaid_for_demo(demo)
  mermaid = "graph TD\n"
  
  # Add changed files with impact styling
  demo[:files].each_with_index do |file, i|
    component = file.split('/').last.gsub('.rb', '').split('_').map(&:capitalize).join
    mermaid += "  #{component}[\"#{component}<br/>#{file}<br/>Impact: #{demo[:impact]}\"]\n"
    
    case demo[:impact]
    when "High"
      mermaid += "  #{component} --> |high impact| SystemCore\n"
    when "Medium"  
      mermaid += "  #{component} --> |medium impact| SystemCore\n"
    else
      mermaid += "  #{component} --> |low impact| SystemCore\n"
    end
  end
  
  # Add dependencies
  demo[:dependencies].each do |dep|
    mermaid += "  #{dep}[(#{dep})]\n"
    mermaid += "  SystemCore --> #{dep}\n"
  end
  
  # Add styling
  mermaid += "\n  classDef highImpact fill:#ff6666\n"
  mermaid += "  classDef mediumImpact fill:#ffaa66\n" 
  mermaid += "  classDef lowImpact fill:#66ff66\n"
  
  demo[:files].each do |file|
    component = file.split('/').last.gsub('.rb', '').split('_').map(&:capitalize).join
    case demo[:impact]
    when "High"
      mermaid += "  class #{component} highImpact\n"
    when "Medium"
      mermaid += "  class #{component} mediumImpact\n"
    else
      mermaid += "  class #{component} lowImpact\n"
    end
  end
  
  mermaid
end

# Demo each scenario
demos.each_with_index do |demo, i|
  puts "\n#{i + 1}. Analyzing: #{demo[:name]}"
  puts "-" * 40
  puts "Files changed: #{demo[:files].join(', ')}"
  puts "Impact level: #{demo[:impact]}"
  puts "Dependencies: #{demo[:dependencies].join(', ')}"
  
  puts "\nGenerated Mermaid diagram:"
  puts "```mermaid"
  puts generate_mermaid_for_demo(demo)
  puts "```"
  puts "\n" + "=" * 50
end

puts "\n🎉 Demo complete! Copy any of the Mermaid diagrams above into:"
puts "   - Mermaid Live Editor: https://mermaid.live/"
puts "   - GitHub README files"  
puts "   - Confluence pages"
puts "   - Or any Mermaid-compatible viewer"

puts "\n💡 For your hackathon presentation:"
puts "   1. Run this script to generate diagrams"
puts "   2. Copy the Mermaid code into mermaid.live"
puts "   3. Show the visual diagrams to demonstrate impact analysis"
puts "   4. Explain how this would work automatically on real PRs"
