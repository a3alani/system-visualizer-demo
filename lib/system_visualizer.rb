# frozen_string_literal: true

require 'fileutils'
require 'json'
require 'set'
require 'net/http'
require 'uri'

class SystemVisualizer
  attr_reader :app_path, :output_path

  def initialize(app_path = 'app', output_path = 'docs/system-diagrams')
    @app_path = app_path
    @output_path = output_path
    @dependencies = {}
    @models = {}
    @controllers = {}
    @services = {}
    @workers = {}
    
    # Enhanced analysis data structures
    @performance_risks = {}
    @security_risks = {}
    @database_impacts = {}
    @api_changes = {}
    @complexity_scores = {}
    @test_coverage = {}
  end

  def analyze
    puts "🔍 Analyzing Rails codebase..."
    
    analyze_models
    analyze_controllers
    analyze_services
    analyze_workers
    
    # Enhanced analysis
    perform_enhanced_analysis
    
    generate_diagrams
    generate_enhanced_reports
    puts "✅ Analysis complete! Diagrams saved to #{output_path}"
  end

  def analyze_pr_changes(base_branch = 'main')
    puts "🔍 Analyzing PR changes..."
    
    # Get changed files from git diff
    changed_files = get_changed_files(base_branch)
    
    # Get individual commits for granular analysis
    commits = get_commits_in_pr(base_branch)
    
    # Analyze only changed files and their dependencies
    changed_files.each do |file|
      case file
      when /app\/models\//
        analyze_model_file(file)
      when /app\/controllers\//
        analyze_controller_file(file)
      when /app\/services\//
        analyze_service_file(file)
      when /app\/workers\//
        analyze_worker_file(file)
      end
    end
    
    # Individual commit analysis
    @commit_analyses = analyze_individual_commits(commits, base_branch)
    
    # Enhanced PR analysis
    perform_pr_enhanced_analysis(changed_files, base_branch)
    
    # Generate both granular and cumulative reports
    generate_commit_reports(@commit_analyses)
    generate_pr_timeline_analysis(@commit_analyses)
    generate_pr_diagram(changed_files)
    generate_enhanced_pr_report(changed_files)
    puts "✅ PR analysis complete!"
  end

  private

  def analyze_models
    Dir.glob("#{app_path}/models/**/*.rb").each do |file|
      analyze_model_file(file)
    end
  end

  def analyze_controllers
    Dir.glob("#{app_path}/controllers/**/*.rb").each do |file|
      analyze_controller_file(file)
    end
  end

  def analyze_services
    Dir.glob("#{app_path}/services/**/*.rb").each do |file|
      analyze_service_file(file)
    end
  end

  def analyze_workers
    Dir.glob("#{app_path}/workers/**/*.rb").each do |file|
      analyze_worker_file(file)
    end
  end

  def analyze_model_file(file_path)
    model_name = extract_model_name(file_path)
    return unless model_name

    content = File.read(file_path)
    dependencies = extract_model_dependencies(content)
    
    @models[model_name] = {
      file: file_path,
      dependencies: dependencies,
      associations: extract_associations(content)
    }
  end

  def analyze_controller_file(file_path)
    controller_name = extract_controller_name(file_path)
    return unless controller_name

    content = File.read(file_path)
    dependencies = extract_controller_dependencies(content)
    
    @controllers[controller_name] = {
      file: file_path,
      dependencies: dependencies,
      actions: extract_actions(content)
    }
  end

  def analyze_service_file(file_path)
    service_name = extract_service_name(file_path)
    return unless service_name

    content = File.read(file_path)
    dependencies = extract_service_dependencies(content)
    
    @services[service_name] = {
      file: file_path,
      dependencies: dependencies
    }
  end

  def analyze_worker_file(file_path)
    worker_name = extract_worker_name(file_path)
    return unless worker_name

    content = File.read(file_path)
    dependencies = extract_worker_dependencies(content)
    
    @workers[worker_name] = {
      file: file_path,
      dependencies: dependencies
    }
  end

  def extract_model_name(file_path)
    match = file_path.match(/models\/(.+)\.rb$/)
    return nil unless match
    
    classify_string(match[1])
  end

  def extract_controller_name(file_path)
    match = file_path.match(/controllers\/(.+)\.rb$/)
    return nil unless match
    
    classify_string(match[1])
  end

  def extract_service_name(file_path)
    match = file_path.match(/services\/(.+)\.rb$/)
    return nil unless match
    
    classify_string(match[1])
  end

  def extract_worker_name(file_path)
    match = file_path.match(/workers\/(.+)\.rb$/)
    return nil unless match
    
    classify_string(match[1])
  end

  def classify_string(str)
    str.split('_').map(&:capitalize).join
  end

  def extract_model_dependencies(content)
    dependencies = Set.new
    
    # Find model dependencies
    content.scan(/belongs_to\s+:(\w+)/) { |match| dependencies << classify_string(match[0]) }
    content.scan(/has_many\s+:(\w+)/) { |match| dependencies << classify_string(match[0]) }
    content.scan(/has_one\s+:(\w+)/) { |match| dependencies << classify_string(match[0]) }
    content.scan(/has_and_belongs_to_many\s+:(\w+)/) { |match| dependencies << classify_string(match[0]) }
    
    # Find service calls
    content.scan(/(\w+)Service\.new/) { |match| dependencies << "#{match[0]}Service" }
    content.scan(/(\w+)Service\.call/) { |match| dependencies << "#{match[0]}Service" }
    
    dependencies.to_a
  end

  def extract_controller_dependencies(content)
    dependencies = Set.new
    
    # Find model usage
    content.scan(/(\w+)\.find/) { |match| dependencies << classify_string(match[0]) }
    content.scan(/(\w+)\.where/) { |match| dependencies << classify_string(match[0]) }
    content.scan(/(\w+)\.new/) { |match| dependencies << classify_string(match[0]) }
    
    # Find service calls
    content.scan(/(\w+)Service\.new/) { |match| dependencies << "#{match[0]}Service" }
    content.scan(/(\w+)Service\.call/) { |match| dependencies << "#{match[0]}Service" }
    
    dependencies.to_a
  end

  def extract_service_dependencies(content)
    dependencies = Set.new
    
    # Find model usage
    content.scan(/(\w+)\.find/) { |match| dependencies << classify_string(match[0]) }
    content.scan(/(\w+)\.where/) { |match| dependencies << classify_string(match[0]) }
    content.scan(/(\w+)\.new/) { |match| dependencies << classify_string(match[0]) }
    
    # Find other service calls
    content.scan(/(\w+)Service\.new/) { |match| dependencies << "#{match[0]}Service" }
    content.scan(/(\w+)Service\.call/) { |match| dependencies << "#{match[0]}Service" }
    
    dependencies.to_a
  end

  def extract_worker_dependencies(content)
    dependencies = Set.new
    
    # Find model usage
    content.scan(/(\w+)\.find/) { |match| dependencies << classify_string(match[0]) }
    content.scan(/(\w+)\.where/) { |match| dependencies << classify_string(match[0]) }
    
    # Find service calls
    content.scan(/(\w+)Service\.new/) { |match| dependencies << "#{match[0]}Service" }
    content.scan(/(\w+)Service\.call/) { |match| dependencies << "#{match[0]}Service" }
    
    dependencies.to_a
  end

  def extract_associations(content)
    associations = {}
    
    content.scan(/(belongs_to|has_many|has_one|has_and_belongs_to_many)\s+:(\w+)/) do |type, name|
      associations[name] = type
    end
    
    associations
  end

  def extract_actions(content)
    actions = []
    
    content.scan(/def\s+(\w+)/) do |action|
      actions << action[0] unless %w[initialize private protected].include?(action[0])
    end
    
    actions
  end

  def get_changed_files(base_branch)
    # First try to fetch the base branch
    system("git fetch origin #{base_branch}:#{base_branch} 2>/dev/null")
    
    # Try different git diff approaches
    diff_output = `git diff --name-only origin/#{base_branch}..HEAD 2>/dev/null`
    if diff_output.empty?
      diff_output = `git diff --name-only #{base_branch}..HEAD 2>/dev/null`
    end
    if diff_output.empty?
      # If all else fails, just return the current staged/unstaged changes
      diff_output = `git diff --name-only HEAD 2>/dev/null`
    end
    
    diff_output.split("\n").select do |file|
      file.start_with?('app/') && !file.empty?
    end
  end

  def get_commits_in_pr(base_branch)
    # Get commits between base branch and current HEAD
    commit_output = `git rev-list --reverse origin/#{base_branch}..HEAD 2>/dev/null`
    if commit_output.empty?
      commit_output = `git rev-list --reverse #{base_branch}..HEAD 2>/dev/null`
    end
    
    commits = commit_output.split("\n").reject(&:empty?)
    
    # Get commit details
    commits.map do |sha|
      message = `git log -1 --pretty=format:"%s" #{sha}`.strip
      author = `git log -1 --pretty=format:"%an" #{sha}`.strip
      date = `git log -1 --pretty=format:"%ai" #{sha}`.strip
      files = `git diff-tree --no-commit-id --name-only -r #{sha}`.split("\n").select { |f| f.start_with?('app/') }
      
      {
        sha: sha,
        short_sha: sha[0..7],
        message: message,
        author: author,
        date: date,
        files: files
      }
    end
  end

  def analyze_individual_commits(commits, base_branch)
    puts "🔍 Analyzing #{commits.size} individual commits..."
    
    commit_analyses = []
    
    commits.each_with_index do |commit, index|
      puts "   📍 Analyzing commit #{index + 1}/#{commits.size}: #{commit[:short_sha]}"
      
      # Analyze files changed in this specific commit
      commit_risks = analyze_commit_risks(commit)
      commit_data = {
        sha: commit[:sha],
        message: commit[:message],
        author: commit[:author],
        date: commit[:date],
        changed_files: commit[:files],
        risks: commit_risks.keys.select { |k| commit_risks[k].any? },
        impact_score: calculate_commit_impact_score(commit),
        dependencies: analyze_commit_dependencies(commit),
        security_risks: (commit_risks[:security] || []).size,
        performance_risks: (commit_risks[:performance] || []).size,
        database_risks: (commit_risks[:database] || []).size,
        test_coverage_risks: (commit_risks[:test_coverage] || []).size
      }
      
      commit_analyses << commit_data
    end
    
    commit_analyses
  end

  def analyze_commit_risks(commit)
    risks = {
      security: [],
      performance: [],
      database: [],
      test_coverage: []
    }
    
    commit[:files].each do |file|
      next unless File.exist?(file)
      
      # Get the actual changes in this commit
      diff_content = `git show #{commit[:sha]} -- #{file}`.strip
      added_lines = diff_content.split("\n").select { |line| line.start_with?('+') && !line.start_with?('+++') }
      
      # Analyze added lines for risks
      added_lines.each do |line|
        clean_line = line[1..-1] # Remove the '+' prefix
        
        # Security risks
        if clean_line.match?(/\.where\(.*#\{.*\}.*\)/)
          risks[:security] << "SQL injection risk added"
        end
        if clean_line.match?(/params\.permit!|params\[.*\]\.permit!/)
          risks[:security] << "Mass assignment vulnerability added"
        end
        if clean_line.match?(/html_safe|raw\(/)
          risks[:security] << "XSS vulnerability risk added"
        end
        
        # Performance risks
        if clean_line.match?(/has_many.*\n.*\.each.*\n.*\.(find|where)/)
          risks[:performance] << "Potential N+1 query pattern added"
        end
        if clean_line.match?(/(\.each|\.map|\.select).*\n.*\.(save|update|create|destroy)/)
          risks[:performance] << "Heavy operation in loop added"
        end
        
        # Database risks
        if clean_line.match?(/belongs_to\s+:(\w+)/)
          risks[:database] << "New association may need index"
        end
        if clean_line.match?(/add_column|remove_column|change_column/)
          risks[:database] << "Schema change detected"
        end
      end
      
      # Test coverage
      if file.match?(/^app\//) && !commit[:files].any? { |f| f.match?(/spec.*#{File.basename(file, '.rb')}/) }
        risks[:test_coverage] << "No test file for #{File.basename(file)}"
      end
    end
    
    risks
  end

  def calculate_commit_impact_score(commit)
    score = 0
    
    # File type weights
    commit[:files].each do |file|
      case file
      when /models/ then score += 5
      when /controllers/ then score += 3
      when /services/ then score += 4
      when /workers/ then score += 2
      when /migrations/ then score += 6
      end
    end
    
    # Number of files
    score += commit[:files].size * 2
    
    # Commit message indicators
    message = commit[:message].downcase
    score += 3 if message.match?(/security|auth|password|login/)
    score += 2 if message.match?(/performance|optimize|cache/)
    score += 4 if message.match?(/database|migration|schema/)
    score += 1 if message.match?(/test|spec/)
    
    # Cap at 100
    [score, 100].min
  end

  def analyze_commit_dependencies(commit)
    dependencies = Set.new
    
    commit[:files].each do |file|
      next unless File.exist?(file)
      
      content = File.read(file)
      
      # Extract dependencies based on file type
      case file
      when /models/
        content.scan(/belongs_to\s+:(\w+)/) { |match| dependencies << classify_string(match[0]) }
        content.scan(/has_many\s+:(\w+)/) { |match| dependencies << classify_string(match[0]) }
      when /controllers/
        content.scan(/(\w+)\.find/) { |match| dependencies << classify_string(match[0]) }
        content.scan(/(\w+)Service\./) { |match| dependencies << "#{match[0]}Service" }
      when /services/
        content.scan(/(\w+)\.find/) { |match| dependencies << classify_string(match[0]) }
        content.scan(/(\w+)Service\./) { |match| dependencies << "#{match[0]}Service" }
      end
    end
    
    dependencies.to_a
  end

  def generate_diagrams
    FileUtils.mkdir_p(output_path)
    
    generate_overview_diagram
    generate_models_diagram
    generate_controllers_diagram
    generate_services_diagram
    generate_workers_diagram
    generate_dependency_analysis
    generate_service_dependency_map
    generate_circular_dependency_analysis
  end

  def generate_pr_diagram(changed_files)
    FileUtils.mkdir_p(output_path)
    
    # Create a focused diagram showing only changed components and their immediate dependencies
    affected_components = Set.new
    
    changed_files.each do |file|
      case file
      when /app\/models\/(.+)\.rb$/
        model_name = classify_string($1)
        affected_components << "Model:#{model_name}"
        @models[model_name]&.dig(:dependencies)&.each { |dep| affected_components << "Model:#{dep}" }
      when /app\/controllers\/(.+)\.rb$/
        controller_name = classify_string($1)
        affected_components << "Controller:#{controller_name}"
        @controllers[controller_name]&.dig(:dependencies)&.each { |dep| affected_components << "Model:#{dep}" }
      when /app\/services\/(.+)\.rb$/
        service_name = classify_string($1)
        affected_components << "Service:#{service_name}"
        @services[service_name]&.dig(:dependencies)&.each { |dep| affected_components << "Model:#{dep}" }
      when /app\/workers\/(.+)\.rb$/
        worker_name = classify_string($1)
        affected_components << "Worker:#{worker_name}"
        @workers[worker_name]&.dig(:dependencies)&.each { |dep| affected_components << "Model:#{dep}" }
      end
    end
    
    generate_pr_mermaid_diagram(affected_components, changed_files)
  end

  def generate_overview_diagram
    mermaid = String.new
    mermaid << "graph TD\n"
    mermaid << "  subgraph \"Rails Application Architecture\"\n"
    
    # Group models by domain
    model_domains = group_models_by_domain
    model_domains.each do |domain, models|
      mermaid << "    subgraph \"#{domain} Models\"\n"
      models.first(5).each do |model| # Show top 5 per domain
        mermaid << "      #{model}[#{model}]\n"
      end
      if models.size > 5
        mermaid << "      ..._#{domain.gsub(/\s+/, '_')}[... #{models.size - 5} more]\n"
      end
      mermaid << "    end\n"
    end
    
    # Show top services by dependency count
    top_services = @services.sort_by { |_, data| data[:dependencies].size }.reverse.first(10)
    mermaid << "    subgraph \"Top Services by Dependencies\"\n"
    top_services.each do |service_name, data|
      mermaid << "      #{service_name}[#{service_name}<br/>#{data[:dependencies].size} deps]\n"
    end
    mermaid << "    end\n"
    
    # Show top controllers by action count
    top_controllers = @controllers.sort_by { |_, data| data[:actions].size }.reverse.first(8)
    mermaid << "    subgraph \"Top Controllers by Actions\"\n"
    top_controllers.each do |controller_name, data|
      mermaid << "      #{controller_name}[#{controller_name}<br/>#{data[:actions].size} actions]\n"
    end
    mermaid << "    end\n"
    
    mermaid << "  end\n\n"
    
    # Add key relationships
    mermaid << "  %% Key architectural relationships\n"
    top_services.first(3).each do |service_name, data|
      data[:dependencies].first(3).each do |dep|
        if @models.key?(dep)
          mermaid << "  #{service_name} -.-> #{dep}\n"
        end
      end
    end
    
    File.write("#{output_path}/overview.md", mermaid)
  end

  def group_models_by_domain
    domains = {
      'User Management' => [],
      'Court Cases' => [],
      'Documents' => [],
      'Payments' => [],
      'Accounting' => [],
      'Communication' => [],
      'Other' => []
    }
    
    @models.keys.each do |model_name|
      case model_name.downcase
      when /user|contact|firm|lawyer|client/
        domains['User Management'] << model_name
      when /court|case|matter/
        domains['Court Cases'] << model_name
      when /document|file|attachment/
        domains['Documents'] << model_name
      when /payment|bill|invoice|charge/
        domains['Payments'] << model_name
      when /account|ledger|journal|transaction/
        domains['Accounting'] << model_name
      when /email|message|notification|reminder/
        domains['Communication'] << model_name
      else
        domains['Other'] << model_name
      end
    end
    
    domains.reject { |_, models| models.empty? }
  end

  def generate_models_diagram
    mermaid = String.new
    mermaid << "graph TD\n"
    
    # Group models by domain for better organization
    model_domains = group_models_by_domain
    
    model_domains.each do |domain, models|
      mermaid << "  subgraph \"#{domain}\"\n"
      models.each do |model_name|
        data = @models[model_name]
        association_count = data[:associations].size
        dependency_count = data[:dependencies].size
        
        # Color code based on complexity
        complexity_class = if dependency_count > 10
                             "highComplexity"
                           elsif dependency_count > 5
                             "mediumComplexity"
                           else
                             "lowComplexity"
                           end
        
        mermaid << "    #{model_name}[#{model_name}<br/>#{association_count} assoc, #{dependency_count} deps]:::#{complexity_class}\n"
      end
      mermaid << "  end\n\n"
    end
    
    # Add key relationships (only show relationships between different domains)
    relationship_count = 0
    max_relationships = 50 # Limit to prevent overwhelming diagram
    
    model_domains.each do |domain1, models1|
      model_domains.each do |domain2, models2|
        next if domain1 == domain2
        
        models1.each do |model1|
          data1 = @models[model1]
          models2.each do |model2|
            if data1[:dependencies].include?(model2) && relationship_count < max_relationships
              mermaid << "  #{model1} -.-> #{model2}\n"
              relationship_count += 1
            end
          end
        end
      end
    end
    
    # Add class definitions for styling
    mermaid << "\n  classDef highComplexity fill:#ffcccc,stroke:#ff6666,stroke-width:2px\n"
    mermaid << "  classDef mediumComplexity fill:#ffffcc,stroke:#ffaa66,stroke-width:2px\n"
    mermaid << "  classDef lowComplexity fill:#ccffcc,stroke:#66ff66,stroke-width:2px\n"
    
    File.write("#{output_path}/models.md", mermaid)
  end

  def generate_controllers_diagram
    mermaid = String.new
    mermaid << "graph TD\n"
    mermaid << "  subgraph \"Controllers\"\n"
    
    @controllers.each do |controller_name, data|
      mermaid << "    #{controller_name}[#{controller_name}]\n"
    end
    
    mermaid << "  end\n\n"
    
    # Add relationships to models and services
    @controllers.each do |controller_name, data|
      data[:dependencies].each do |dependency|
        if @models.key?(dependency)
          mermaid << "  #{controller_name} --> #{dependency}\n"
        elsif @services.key?(dependency)
          mermaid << "  #{controller_name} --> #{dependency}\n"
        end
      end
    end
    
    File.write("#{output_path}/controllers.md", mermaid)
  end

  def generate_services_diagram
    mermaid = String.new
    mermaid << "graph TD\n"
    mermaid << "  subgraph \"Services\"\n"
    
    @services.each do |service_name, data|
      mermaid << "    #{service_name}[#{service_name}]\n"
    end
    
    mermaid << "  end\n\n"
    
    # Add relationships
    @services.each do |service_name, data|
      data[:dependencies].each do |dependency|
        if @models.key?(dependency)
          mermaid << "  #{service_name} --> #{dependency}\n"
        elsif @services.key?(dependency)
          mermaid << "  #{service_name} --> #{dependency}\n"
        end
      end
    end
    
    File.write("#{output_path}/services.md", mermaid)
  end

  def generate_workers_diagram
    mermaid = String.new
    mermaid << "graph TD\n"
    mermaid << "  subgraph \"Workers\"\n"
    
    @workers.each do |worker_name, data|
      mermaid << "    #{worker_name}[#{worker_name}]\n"
    end
    
    mermaid << "  end\n\n"
    
    # Add relationships
    @workers.each do |worker_name, data|
      data[:dependencies].each do |dependency|
        if @models.key?(dependency)
          mermaid << "  #{worker_name} --> #{dependency}\n"
        elsif @services.key?(dependency)
          mermaid << "  #{worker_name} --> #{dependency}\n"
        end
      end
    end
    
    File.write("#{output_path}/workers.md", mermaid)
  end

  def generate_dependency_analysis
    mermaid = String.new
    mermaid << "graph TD\n"
    mermaid << "  subgraph \"Dependency Analysis\"\n"
    
    # Find most dependent models (models that are depended on the most)
    dependency_counts = Hash.new(0)
    @models.each do |model_name, data|
      data[:dependencies].each do |dep|
        dependency_counts[dep] += 1
      end
    end
    
    # Show top 15 most depended-on models
    top_dependent_models = dependency_counts.sort_by { |_, count| count }.reverse.first(15)
    
    mermaid << "    subgraph \"Most Referenced Models\"\n"
    top_dependent_models.each do |model_name, count|
      impact_class = if count > 20
                       "highImpact"
                     elsif count > 10
                       "mediumImpact"
                     else
                       "lowImpact"
                     end
      mermaid << "      #{model_name}[#{model_name}<br/>#{count} references]:::#{impact_class}\n"
    end
    mermaid << "    end\n"
    
    # Show models with most dependencies
    most_dependent = @models.sort_by { |_, data| data[:dependencies].size }.reverse.first(10)
    mermaid << "    subgraph \"Models with Most Dependencies\"\n"
    most_dependent.each do |model_name, data|
      complexity_class = if data[:dependencies].size > 15
                           "highComplexity"
                         elsif data[:dependencies].size > 8
                           "mediumComplexity"
                         else
                           "lowComplexity"
                         end
      mermaid << "      #{model_name}[#{model_name}<br/>#{data[:dependencies].size} deps]:::#{complexity_class}\n"
    end
    mermaid << "    end\n"
    
    mermaid << "  end\n\n"
    
    # Show key dependency relationships
    mermaid << "  %% Key dependency relationships\n"
    top_dependent_models.first(5).each do |model_name, _|
      @models.each do |dependent_model, data|
        if data[:dependencies].include?(model_name)
          mermaid << "  #{dependent_model} --> #{model_name}\n"
        end
      end
    end
    
    # Add class definitions for styling
    mermaid << "\n  classDef highImpact fill:#ff6666,stroke:#cc0000,stroke-width:2px\n"
    mermaid << "  classDef mediumImpact fill:#ffaa66,stroke:#cc6600,stroke-width:2px\n"
    mermaid << "  classDef lowImpact fill:#66ff66,stroke:#00cc00,stroke-width:2px\n"
    mermaid << "  classDef highComplexity fill:#ffcccc,stroke:#ff6666,stroke-width:2px\n"
    mermaid << "  classDef mediumComplexity fill:#ffffcc,stroke:#ffaa66,stroke-width:2px\n"
    mermaid << "  classDef lowComplexity fill:#ccffcc,stroke:#66ff66,stroke-width:2px\n"
    
    File.write("#{output_path}/dependency-analysis.md", mermaid)
  end

  def generate_service_dependency_map
    mermaid = String.new
    mermaid << "graph TD\n"
    mermaid << "  subgraph \"Service Dependency Map\"\n"
    
    # Group services by domain
    service_domains = group_services_by_domain
    
    service_domains.each do |domain, services|
      mermaid << "    subgraph \"#{domain} Services\"\n"
      services.each do |service_name|
        data = @services[service_name]
        dependency_count = data[:dependencies].size
        
        complexity_class = if dependency_count > 8
                             "highComplexity"
                           elsif dependency_count > 4
                             "mediumComplexity"
                           else
                             "lowComplexity"
                           end
        
        mermaid << "      #{service_name}[#{service_name}<br/>#{dependency_count} deps]:::#{complexity_class}\n"
      end
      mermaid << "    end\n"
    end
    
    mermaid << "  end\n\n"
    
    # Show service-to-service dependencies
    service_dependencies = 0
    max_service_deps = 30
    
    @services.each do |service_name, data|
      data[:dependencies].each do |dep|
        if @services.key?(dep) && service_dependencies < max_service_deps
          mermaid << "  #{service_name} -.-> #{dep}\n"
          service_dependencies += 1
        end
      end
    end
    
    # Add class definitions for styling
    mermaid << "\n  classDef highComplexity fill:#ffcccc,stroke:#ff6666,stroke-width:2px\n"
    mermaid << "  classDef mediumComplexity fill:#ffffcc,stroke:#ffaa66,stroke-width:2px\n"
    mermaid << "  classDef lowComplexity fill:#ccffcc,stroke:#66ff66,stroke-width:2px\n"
    
    File.write("#{output_path}/service-dependency-map.md", mermaid)
  end

  def group_services_by_domain
    domains = {
      'User Management' => [],
      'Court Cases' => [],
      'Documents' => [],
      'Payments' => [],
      'Accounting' => [],
      'Communication' => [],
      'Integration' => [],
      'Other' => []
    }
    
    @services.keys.each do |service_name|
      case service_name.downcase
      when /user|contact|firm|lawyer|client|auth/
        domains['User Management'] << service_name
      when /court|case|matter/
        domains['Court Cases'] << service_name
      when /document|file|attachment/
        domains['Documents'] << service_name
      when /payment|bill|invoice|charge/
        domains['Payments'] << service_name
      when /account|ledger|journal|transaction/
        domains['Accounting'] << service_name
      when /email|message|notification|reminder/
        domains['Communication'] << service_name
      when /integration|sync|api|webhook/
        domains['Integration'] << service_name
      else
        domains['Other'] << service_name
      end
    end
    
    domains.reject { |_, services| services.empty? }
  end

  def generate_circular_dependency_analysis
    mermaid = String.new
    mermaid << "graph TD\n"
    mermaid << "  subgraph \"Circular Dependency Analysis\"\n"
    
    # Find potential circular dependencies
    circular_deps = find_circular_dependencies
    
    if circular_deps.any?
      mermaid << "    subgraph \"Circular Dependencies Found\"\n"
      circular_deps.each_with_index do |cycle, index|
        cycle.each_with_index do |component, i|
          next_component = cycle[(i + 1) % cycle.size]
          mermaid << "      #{component} --> #{next_component}\n"
        end
      end
      mermaid << "    end\n"
    else
      mermaid << "    NoCircular[No circular dependencies found]:::lowComplexity\n"
    end
    
    # Show high complexity areas
    high_complexity = find_high_complexity_areas
    mermaid << "    subgraph \"High Complexity Areas\"\n"
    high_complexity.each do |component, complexity_score|
      mermaid << "      #{component}[#{component}<br/>Complexity: #{complexity_score}]:::highComplexity\n"
    end
    mermaid << "    end\n"
    
    mermaid << "  end\n"
    
    # Add class definitions for styling
    mermaid << "\n  classDef highComplexity fill:#ffcccc,stroke:#ff6666,stroke-width:2px\n"
    mermaid << "  classDef mediumComplexity fill:#ffffcc,stroke:#ffaa66,stroke-width:2px\n"
    mermaid << "  classDef lowComplexity fill:#ccffcc,stroke:#66ff66,stroke-width:2px\n"
    
    File.write("#{output_path}/circular-dependency-analysis.md", mermaid)
  end

  def find_circular_dependencies
    # Simple circular dependency detection
    circular_deps = []
    
    @models.each do |model_name, data|
      data[:dependencies].each do |dep|
        if @models.key?(dep)
          dep_data = @models[dep]
          if dep_data[:dependencies].include?(model_name)
            circular_deps << [model_name, dep]
          end
        end
      end
    end
    
    circular_deps.uniq
  end

  def find_high_complexity_areas
    complexity_scores = {}
    
    # Calculate complexity for models
    @models.each do |model_name, data|
      score = data[:dependencies].size + data[:associations].size
      complexity_scores[model_name] = score if score > 10
    end
    
    # Calculate complexity for services
    @services.each do |service_name, data|
      score = data[:dependencies].size
      complexity_scores[service_name] = score if score > 8
    end
    
    complexity_scores.sort_by { |_, score| score }.reverse.first(10)
  end

  def generate_pr_mermaid_diagram(affected_components, changed_files)
    mermaid = String.new
    mermaid << "graph TD\n"
    mermaid << "  subgraph \"PR Impact Analysis\"\n"
    
    # Group components by type
    models = affected_components.select { |c| c.start_with?('Model:') }.map { |c| c.gsub('Model:', '') }
    controllers = affected_components.select { |c| c.start_with?('Controller:') }.map { |c| c.gsub('Controller:', '') }
    services = affected_components.select { |c| c.start_with?('Service:') }.map { |c| c.gsub('Service:', '') }
    workers = affected_components.select { |c| c.start_with?('Worker:') }.map { |c| c.gsub('Worker:', '') }
    
    # Add changed files with impact level
    mermaid << "    subgraph \"Changed Files\"\n"
    changed_files.each do |file|
      impact_level = calculate_file_impact(file)
      impact_class = case impact_level
                     when 'high'
                       "highImpact"
                     when 'medium'
                       "mediumImpact"
                     else
                       "lowImpact"
                     end
      mermaid << "      #{file.gsub(/[^a-zA-Z0-9]/, '_')}[#{File.basename(file)}<br/>#{impact_level} impact]:::#{impact_class}\n"
    end
    mermaid << "    end\n\n"
    
    # Add affected components with dependency info
    if models.any?
      mermaid << "    subgraph \"Affected Models\"\n"
      models.each do |model|
        data = @models[model]
        if data
          dependency_count = data[:dependencies].size
          association_count = data[:associations].size
          mermaid << "      #{model}[#{model}<br/>#{dependency_count} deps, #{association_count} assoc]\n"
        else
          mermaid << "      #{model}[#{model}]\n"
        end
      end
      mermaid << "    end\n\n"
    end
    
    if controllers.any?
      mermaid << "    subgraph \"Affected Controllers\"\n"
      controllers.each do |controller|
        data = @controllers[controller]
        if data
          dependency_count = data[:dependencies].size
          action_count = data[:actions].size
          mermaid << "      #{controller}[#{controller}<br/>#{dependency_count} deps, #{action_count} actions]\n"
        else
          mermaid << "      #{controller}[#{controller}]\n"
        end
      end
      mermaid << "    end\n\n"
    end
    
    if services.any?
      mermaid << "    subgraph \"Affected Services\"\n"
      services.each do |service|
        data = @services[service]
        if data
          dependency_count = data[:dependencies].size
          mermaid << "      #{service}[#{service}<br/>#{dependency_count} deps]\n"
        else
          mermaid << "      #{service}[#{service}]\n"
        end
      end
      mermaid << "    end\n\n"
    end
    
    if workers.any?
      mermaid << "    subgraph \"Affected Workers\"\n"
      workers.each do |worker|
        data = @workers[worker]
        if data
          dependency_count = data[:dependencies].size
          mermaid << "      #{worker}[#{worker}<br/>#{dependency_count} deps]\n"
        else
          mermaid << "      #{worker}[#{worker}]\n"
        end
      end
      mermaid << "    end\n\n"
    end
    
    mermaid << "  end\n\n"
    
    # Add detailed relationships
    mermaid << "  %% Direct file changes\n"
    changed_files.each do |file|
      case file
      when /app\/models\/(.+)\.rb$/
        model_name = classify_string($1)
        mermaid << "  #{file.gsub(/[^a-zA-Z0-9]/, '_')} --> #{model_name}\n"
      when /app\/controllers\/(.+)\.rb$/
        controller_name = classify_string($1)
        mermaid << "  #{file.gsub(/[^a-zA-Z0-9]/, '_')} --> #{controller_name}\n"
      when /app\/services\/(.+)\.rb$/
        service_name = classify_string($1)
        mermaid << "  #{file.gsub(/[^a-zA-Z0-9]/, '_')} --> #{service_name}\n"
      when /app\/workers\/(.+)\.rb$/
        worker_name = classify_string($1)
        mermaid << "  #{file.gsub(/[^a-zA-Z0-9]/, '_')} --> #{worker_name}\n"
      end
    end
    
    # Add dependency relationships between affected components
    mermaid << "  %% Dependency relationships\n"
    models.each do |model|
      data = @models[model]
      if data
        data[:dependencies].each do |dep|
          if models.include?(dep) || controllers.include?(dep) || services.include?(dep)
            mermaid << "  #{model} -.-> #{dep}\n"
          end
        end
      end
    end
    
    controllers.each do |controller|
      data = @controllers[controller]
      if data
        data[:dependencies].each do |dep|
          if models.include?(dep) || services.include?(dep)
            mermaid << "  #{controller} -.-> #{dep}\n"
          end
        end
      end
    end
    
    # Add class definitions for styling
    mermaid << "\n  classDef highImpact fill:#ff6666,stroke:#cc0000,stroke-width:2px\n"
    mermaid << "  classDef mediumImpact fill:#ffaa66,stroke:#cc6600,stroke-width:2px\n"
    mermaid << "  classDef lowImpact fill:#66ff66,stroke:#00cc00,stroke-width:2px\n"
    mermaid << "  classDef highComplexity fill:#ffcccc,stroke:#ff6666,stroke-width:2px\n"
    mermaid << "  classDef mediumComplexity fill:#ffffcc,stroke:#ffaa66,stroke-width:2px\n"
    mermaid << "  classDef lowComplexity fill:#ccffcc,stroke:#66ff66,stroke-width:2px\n"
    mermaid << "  classDef criticalRisk fill:#cc0000,stroke:#990000,stroke-width:3px,color:#ffffff\n"
    mermaid << "  classDef highRisk fill:#ff3333,stroke:#cc0000,stroke-width:2px\n"
    mermaid << "  classDef mediumRisk fill:#ffaa66,stroke:#cc6600,stroke-width:2px\n"
    mermaid << "  classDef lowRisk fill:#66ff66,stroke:#00cc00,stroke-width:2px\n"
    
    File.write("#{output_path}/pr-changes.md", mermaid)
  end

  def calculate_file_impact(file_path)
    case file_path
    when /app\/models\//
      'high' # Model changes can affect many other components
    when /app\/services\//
      'medium' # Service changes affect business logic
    when /app\/controllers\//
      'medium' # Controller changes affect API/UI
    when /app\/workers\//
      'low' # Worker changes usually isolated
    else
      'low'
    end
  end

  def perform_enhanced_analysis
    # Performance Risk Detection
    @performance_risks = detect_performance_risks
    # Security Risk Detection
    @security_risks = detect_security_risks
    # Database Impact Detection
    @database_impacts = detect_database_impacts
    # API Changes Detection
    @api_changes = detect_api_changes
    # Complexity Score Calculation
    @complexity_scores = calculate_complexity_scores
    # Test Coverage Analysis
    @test_coverage = analyze_test_coverage
  end

  def detect_performance_risks
    risks = {}
    
    # Analyze models for potential N+1 queries
    risks['N+1 Query Risks'] = {}
    @models.each do |model_name, data|
      content = File.read(data[:file]) if File.exist?(data[:file])
      if content&.match?(/has_many.*:(\w+).*\n.*\1\./)
        risks['N+1 Query Risks'][model_name] = "Potential N+1 query in associations"
      end
    end
    
    # Analyze controllers for heavy operations
    risks['Heavy Operations'] = {}
    @controllers.each do |controller_name, data|
      content = File.read(data[:file]) if File.exist?(data[:file])
      if content&.match?(/(\.each|\.map|\.select|\.find_each).*\n.*\.(save|update|create|destroy)/)
        risks['Heavy Operations'][controller_name] = "Bulk operations in controller"
      end
    end
    
    # Check for large result sets
    risks['Large Result Sets'] = {}
    all_files = [@models, @controllers, @services, @workers].flat_map { |h| h.values }
    all_files.each do |data|
      next unless data[:file] && File.exist?(data[:file])
      content = File.read(data[:file])
      if content.match?(/(\.all\b|\.where\(.*\)$)/) && !content.match?(/limit\(|\.first\(|\.last\(/)
        component_name = File.basename(data[:file], '.rb')
        risks['Large Result Sets'][component_name] = "Queries without pagination/limits"
      end
    end
    
    risks.reject { |_, v| v.empty? }
  end

  def detect_security_risks
    risks = {}
    
    # Check for SQL injection vulnerabilities  
    risks['SQL Injection'] = {}
    all_files = [@models, @controllers, @services, @workers].flat_map { |h| h.values }
    all_files.each do |data|
      next unless data[:file] && File.exist?(data[:file])
      content = File.read(data[:file])
      if content.match?(/\.where\(.*["'].*#\{.*\}.*["'].*\)/)
        component_name = File.basename(data[:file], '.rb')
        risks['SQL Injection'][component_name] = "String interpolation in SQL queries"
      end
    end
    
    # Check for missing authentication
    risks['Authentication Issues'] = {}
    @controllers.each do |controller_name, data|
      content = File.read(data[:file]) if File.exist?(data[:file])
      auth_pattern = /(before_action.*authenticate|protect_from_forgery|skip_before_action.*verify_authenticity_token)/
      if content && !content.match?(auth_pattern)
        risks['Authentication Issues'][controller_name] = "No authentication checks found"
      end
    end
    
    # Check for mass assignment vulnerabilities
    risks['Mass Assignment'] = {}
    @controllers.each do |controller_name, data|
      content = File.read(data[:file]) if File.exist?(data[:file])
      if content&.match?(/params\[:(\w+)\]\.permit!/)
        risks['Mass Assignment'][controller_name] = "Mass assignment with permit!"
      end
    end
    
    risks.reject { |_, v| v.empty? }
  end

  def detect_database_impacts
    impacts = {}
    
    # Check for missing indexes on foreign keys
    impacts['Missing Indexes'] = {}
    @models.each do |model_name, data|
      content = File.read(data[:file]) if File.exist?(data[:file])
      foreign_keys = content&.scan(/belongs_to\s+:(\w+)/)&.flatten || []
      foreign_keys.each do |fk|
        impacts['Missing Indexes']["#{model_name}_#{fk}_id"] = "Consider adding index on #{fk}_id"
      end
    end
    
    # Check for expensive operations
    impacts['Expensive Operations'] = {}
    all_files = [@models, @controllers, @services, @workers].flat_map { |h| h.values }
    all_files.each do |data|
      next unless data[:file] && File.exist?(data[:file])
      content = File.read(data[:file])
      if content.match?(/(LIKE '%.*%'|\.size\b|\.count\b.*\.where|\.sum\(|\.average\()/)
        component_name = File.basename(data[:file], '.rb')
        impacts['Expensive Operations'][component_name] = "Contains potentially expensive DB operations"
      end
    end
    
    # Check for schema changes
    impacts['Schema Changes'] = {}
    @models.each do |model_name, data|
      content = File.read(data[:file]) if File.exist?(data[:file])
      if content&.match?(/(add_column|remove_column|change_column|add_index|remove_index)/)
        impacts['Schema Changes'][model_name] = "Contains migration operations"
      end
    end
    
    impacts.reject { |_, v| v.empty? }
  end

  def detect_api_changes
    changes = {}
    
    # Check for new routes/endpoints
    changes['Route Changes'] = {}
    @controllers.each do |controller_name, data|
      content = File.read(data[:file]) if File.exist?(data[:file])
      if content
        new_actions = content.scan(/def\s+(\w+)/).flatten - %w[initialize private protected]
        if new_actions.any?
          changes['Route Changes'][controller_name] = "#{new_actions.size} actions: #{new_actions.join(', ')}"
        end
      end
    end
    
    # Check for API version changes
    changes['API Version Changes'] = {}
    if File.exist?('config/routes.rb')
      routes_content = File.read('config/routes.rb')
      api_versions = routes_content.scan(/namespace\s*:v(\d+)/).flatten
      if api_versions.any?
        changes['API Version Changes']['api_versions'] = "API versions found: #{api_versions.join(', ')}"
      end
    end
    
    # Check for serializer changes
    changes['Serialization Changes'] = {}
    if Dir.exist?('app/serializers')
      Dir.glob('app/serializers/**/*.rb').each do |file|
        serializer_name = File.basename(file, '.rb')
        changes['Serialization Changes'][serializer_name] = "Serializer present"
      end
    end
    
    changes.reject { |_, v| v.empty? }
  end

  def calculate_complexity_scores
    scores = {}
    # Simple complexity score: dependencies + associations
    @models.each do |model_name, data|
      scores[model_name] = data[:dependencies].size + data[:associations].size
    end
    @services.each do |service_name, data|
      scores[service_name] = data[:dependencies].size
    end
    scores
  end

  def analyze_test_coverage
    coverage = {}
    
    # Check for test files existence
    coverage['Test Files'] = {}
    [@models, @controllers, @services, @workers].each do |component_hash|
      component_hash.each do |name, data|
        test_file_patterns = [
          "spec/#{data[:file].gsub('app/', '')}_spec.rb",
          "test/#{data[:file].gsub('app/', '')}_test.rb",
          "spec/#{data[:file].gsub('app/', '').gsub('.rb', '')}_spec.rb",
          "test/#{data[:file].gsub('app/', '').gsub('.rb', '')}_test.rb"
        ]
        
        has_test = test_file_patterns.any? { |pattern| File.exist?(pattern) }
        coverage['Test Files'][name] = has_test ? "Has tests" : "Missing tests"
      end
    end
    
    # Check for factory files
    coverage['Factory Coverage'] = {}
    @models.each do |model_name, _|
      factory_patterns = [
        "spec/factories/#{model_name.downcase.gsub(/([A-Z])/, '_\1').sub(/^_/, '')}.rb",
        "test/factories/#{model_name.downcase.gsub(/([A-Z])/, '_\1').sub(/^_/, '')}.rb",
        "spec/factories/#{model_name.downcase}s.rb",
        "test/factories/#{model_name.downcase}s.rb"
      ]
      
      has_factory = factory_patterns.any? { |pattern| File.exist?(pattern) }
      coverage['Factory Coverage'][model_name] = has_factory ? "Has factory" : "Missing factory"
    end
    
    # Analyze test complexity
    coverage['Test Complexity'] = {}
    test_files = Dir.glob("{spec,test}/**/*_{spec,test}.rb")
    test_files.each do |test_file|
      content = File.read(test_file)
      test_count = content.scan(/it\s+['"]|test\s+['"]|should\s+['"]/).size
      describe_count = content.scan(/describe\s+|context\s+/).size
      
      if test_count > 0
        complexity = if test_count > 20 then "High"
                    elsif test_count > 10 then "Medium"  
                    else "Low"
                    end
        coverage['Test Complexity'][File.basename(test_file)] = "#{test_count} tests, #{describe_count} groups (#{complexity})"
      end
    end
    
    coverage.reject { |_, v| v.empty? }
  end

  def perform_pr_enhanced_analysis(changed_files, base_branch)
    puts "🔍 Performing enhanced PR analysis..."
    
    # Analyze changed files for specific risks
    @pr_performance_risks = analyze_pr_performance_risks(changed_files)
    @pr_security_risks = analyze_pr_security_risks(changed_files)  
    @pr_database_impacts = analyze_pr_database_impacts(changed_files)
    @pr_test_impacts = analyze_pr_test_impacts(changed_files)
    @pr_ai_risk_score = calculate_ai_risk_score(changed_files)
    
    puts "✅ Enhanced PR analysis complete!"
  end

  def analyze_pr_performance_risks(changed_files)
    risks = {}
    changed_files.each do |file|
      next unless File.exist?(file)
      content = File.read(file)
      
      # Check for new N+1 queries
      if content.match?(/has_many.*\n.*\.each.*\n.*\.(find|where)/)
        risks[file] = (risks[file] || []) << "Potential N+1 query introduced"
      end
      
      # Check for missing eager loading
      if content.match?(/\.includes?\(.*\)/) && content.match?(/\.(find|where|all)/)
        risks[file] = (risks[file] || []) << "Consider eager loading optimization"
      end
      
      # Check for expensive operations in views/controllers
      if file.match?(/controllers/) && content.match?(/(\.size|\.count|\.sum)/)
        risks[file] = (risks[file] || []) << "Expensive calculations in controller"
      end
    end
    risks
  end

  def analyze_pr_security_risks(changed_files)
    risks = {}
    changed_files.each do |file|
      next unless File.exist?(file)
      content = File.read(file)
      
      # Check for authentication bypass
      if content.match?(/skip_before_action.*authenticate/)
        risks[file] = (risks[file] || []) << "Authentication bypass detected"
      end
      
      # Check for unsafe parameter handling
      if content.match?(/params\.permit!|params\[.*\]\.permit!/)
        risks[file] = (risks[file] || []) << "Mass assignment vulnerability"
      end
      
      # Check for SQL injection risks
      if content.match?(/\.where\(.*#\{.*\}.*\)/)
        risks[file] = (risks[file] || []) << "Potential SQL injection"
      end
      
      # Check for XSS vulnerabilities  
      if content.match?(/html_safe|raw\(/)
        risks[file] = (risks[file] || []) << "Potential XSS vulnerability"
      end
    end
    risks
  end

  def analyze_pr_database_impacts(changed_files)
    impacts = {}
    changed_files.each do |file|
      next unless File.exist?(file)
      content = File.read(file)
      
      # Check for new associations without indexes
      foreign_keys = content.scan(/belongs_to\s+:(\w+)/).flatten
      if foreign_keys.any?
        impacts[file] = (impacts[file] || []) << "New associations may need indexes: #{foreign_keys.join(', ')}"
      end
      
      # Check for schema changes
      if content.match?(/(add_column|remove_column|change_column|add_index|remove_index)/)
        impacts[file] = (impacts[file] || []) << "Database schema changes detected"
      end
      
      # Check for data migrations
      if content.match?(/\.update_all|\.delete_all|\.destroy_all/)
        impacts[file] = (impacts[file] || []) << "Bulk data operations detected"
      end
    end
    impacts
  end

  def analyze_pr_test_impacts(changed_files)
    impacts = {}
    
    # Find corresponding test files for changed files
    changed_files.each do |file|
      test_patterns = [
        file.gsub('app/', 'spec/').gsub('.rb', '_spec.rb'),
        file.gsub('app/', 'test/').gsub('.rb', '_test.rb')
      ]
      
      existing_tests = test_patterns.select { |pattern| File.exist?(pattern) }
      
      if existing_tests.empty?
        impacts[file] = "No corresponding test file found"
      else
        # Analyze test coverage for changed methods
        content = File.read(file)
        methods = content.scan(/def\s+(\w+)/).flatten - %w[initialize private protected]
        
        existing_tests.each do |test_file|
          test_content = File.read(test_file)
          tested_methods = methods.select { |method| test_content.include?(method) }
          untested_methods = methods - tested_methods
          
          if untested_methods.any?
            impacts[file] = "Methods lacking tests: #{untested_methods.join(', ')}"
          end
        end
      end
    end
    
    impacts
  end

  def calculate_ai_risk_score(changed_files)
    # Simulated AI risk scoring based on multiple factors
    total_score = 0
    max_score = 100
    
    factors = {
      file_count: changed_files.size,
      model_changes: changed_files.count { |f| f.include?('models/') },
      controller_changes: changed_files.count { |f| f.include?('controllers/') },
      service_changes: changed_files.count { |f| f.include?('services/') },
      test_changes: changed_files.count { |f| f.include?('spec/') || f.include?('test/') }
    }
    
    # Weight different types of changes
    weights = {
      file_count: 2,
      model_changes: 5,      # Models are high impact
      controller_changes: 3,  # Controllers are medium-high impact  
      service_changes: 4,     # Services are high impact
      test_changes: -2        # Tests reduce risk
    }
    
    factors.each do |factor, count|
      total_score += count * weights[factor]
    end
    
    # Normalize to 0-100 scale
    risk_score = [[total_score, 0].max, max_score].min
    
    {
      score: risk_score,
      level: case risk_score
             when 0..30 then "Low"
             when 31..60 then "Medium"  
             when 61..80 then "High"
             else "Critical"
             end,
      factors: factors,
      recommendations: generate_ai_recommendations(factors, risk_score)
    }
  end

  def generate_ai_recommendations(factors, risk_score)
    recommendations = []
    
    if factors[:model_changes] > 3
      recommendations << "Consider breaking down model changes into smaller PRs"
    end
    
    if factors[:test_changes] == 0 && factors[:file_count] > 1
      recommendations << "Add tests for the changes to reduce risk"
    end
    
    if risk_score > 60
      recommendations << "This PR has high complexity - consider additional code review"
    end
    
    if factors[:controller_changes] > 2
      recommendations << "Multiple controller changes detected - verify API contracts"
    end
    
    if factors[:service_changes] > 1
      recommendations << "Service layer changes may affect multiple consumers"
    end
    
    recommendations
  end

  def generate_enhanced_reports
    FileUtils.mkdir_p("#{output_path}/reports")

    generate_performance_report
    generate_security_report
    generate_database_impact_report
    generate_api_changes_report
    generate_complexity_report
    generate_test_coverage_report
  end

  def generate_performance_report
    mermaid = String.new
    mermaid << "graph TD\n"
    mermaid << "  subgraph \"Performance Risks\"\n"
    
    @performance_risks.each do |risk_type, details|
      mermaid << "    subgraph \"#{risk_type}\"\n"
      details.each do |item, description|
        mermaid << "      #{item}[#{item}<br/>#{description}]\n"
      end
      mermaid << "    end\n"
    end
    
    mermaid << "  end\n\n"
    
    File.write("#{output_path}/reports/performance.md", mermaid)
  end

  def generate_security_report
    mermaid = String.new
    mermaid << "graph TD\n"
    mermaid << "  subgraph \"Security Risks\"\n"
    
    @security_risks.each do |risk_type, details|
      mermaid << "    subgraph \"#{risk_type}\"\n"
      details.each do |item, description|
        mermaid << "      #{item}[#{item}<br/>#{description}]\n"
      end
      mermaid << "    end\n"
    end
    
    mermaid << "  end\n\n"
    
    File.write("#{output_path}/reports/security.md", mermaid)
  end

  def generate_database_impact_report
    mermaid = String.new
    mermaid << "graph TD\n"
    mermaid << "  subgraph \"Database Impact\"\n"
    
    @database_impacts.each do |impact_type, details|
      mermaid << "    subgraph \"#{impact_type}\"\n"
      details.each do |item, description|
        mermaid << "      #{item}[#{item}<br/>#{description}]\n"
      end
      mermaid << "    end\n"
    end
    
    mermaid << "  end\n\n"
    
    File.write("#{output_path}/reports/database_impact.md", mermaid)
  end

  def generate_api_changes_report
    mermaid = String.new
    mermaid << "graph TD\n"
    mermaid << "  subgraph \"API Changes\"\n"
    
    @api_changes.each do |change_type, details|
      mermaid << "    subgraph \"#{change_type}\"\n"
      details.each do |item, description|
        mermaid << "      #{item}[#{item}<br/>#{description}]\n"
      end
      mermaid << "    end\n"
    end
    
    mermaid << "  end\n\n"
    
    File.write("#{output_path}/reports/api_changes.md", mermaid)
  end

  def generate_complexity_report
    mermaid = String.new
    mermaid << "graph TD\n"
    mermaid << "  subgraph \"Complexity Analysis\"\n"
    
    # Show top 10 most complex components
    top_complexity = @complexity_scores.sort_by { |_, score| score }.reverse.first(10)
    
    mermaid << "    subgraph \"Top Complex Components\"\n"
    top_complexity.each do |component, score|
      mermaid << "      #{component}[#{component}<br/>Complexity: #{score}]:::#{complexity_class_for_score(score)}\n"
    end
    mermaid << "    end\n"
    
    # Show models with most dependencies
    most_dependent = @models.sort_by { |_, data| data[:dependencies].size }.reverse.first(10)
    mermaid << "    subgraph \"Models with Most Dependencies\"\n"
    most_dependent.each do |model_name, data|
      complexity_class = if data[:dependencies].size > 15
                           "highComplexity"
                         elsif data[:dependencies].size > 8
                           "mediumComplexity"
                         else
                           "lowComplexity"
                         end
      mermaid << "      #{model_name}[#{model_name}<br/>#{data[:dependencies].size} deps]:::#{complexity_class}\n"
    end
    mermaid << "    end\n"
    
    mermaid << "  end\n\n"
    
    # Add class definitions for styling
    mermaid << "\n  classDef highComplexity fill:#ffcccc,stroke:#ff6666,stroke-width:2px\n"
    mermaid << "  classDef mediumComplexity fill:#ffffcc,stroke:#ffaa66,stroke-width:2px\n"
    mermaid << "  classDef lowComplexity fill:#ccffcc,stroke:#66ff66,stroke-width:2px\n"
    
    File.write("#{output_path}/reports/complexity.md", mermaid)
  end

  def generate_test_coverage_report
    mermaid = String.new
    mermaid << "graph TD\n"
    mermaid << "  subgraph \"Test Coverage Analysis\"\n"
    
    @test_coverage.each do |test_type, details|
      mermaid << "    subgraph \"#{test_type}\"\n"
      details.each do |item, description|
        mermaid << "      #{item}[#{item}<br/>#{description}]\n"
      end
      mermaid << "    end\n"
    end
    
    mermaid << "  end\n\n"
    
    File.write("#{output_path}/reports/test_coverage.md", mermaid)
  end

  def complexity_class_for_score(score)
    if score > 20
      "highComplexity"
    elsif score > 10
      "mediumComplexity"
    else
      "lowComplexity"
    end
  end

  def generate_enhanced_pr_report(changed_files)
    # Generate comprehensive PR analysis report
    generate_pr_risk_assessment_report(changed_files)
    generate_pr_impact_summary_report(changed_files)
    generate_exportable_reports(changed_files)
    
    mermaid = String.new("")
    mermaid << "graph TD\n"
    mermaid << "  subgraph \"Enhanced PR Report\"\n"
    
    # Add AI Risk Score prominently
    if @pr_ai_risk_score
      risk_class = case @pr_ai_risk_score[:level]
                   when "Critical" then "criticalRisk"
                   when "High" then "highRisk"
                   when "Medium" then "mediumRisk"
                   else "lowRisk"
                   end
      mermaid << "    AIRisk[\"🤖 AI Risk Score: #{@pr_ai_risk_score[:score]}/100<br/>Level: #{@pr_ai_risk_score[:level]}\"]:::#{risk_class}\n"
    end
    
    # Group components by type
    models = changed_files.select { |f| f.start_with?('app/models/') }.map { |f| classify_string(File.basename(f, '.rb')) }
    controllers = changed_files.select { |f| f.start_with?('app/controllers/') }.map { |f| classify_string(File.basename(f, '.rb')) }
    services = changed_files.select { |f| f.start_with?('app/services/') }.map { |f| classify_string(File.basename(f, '.rb')) }
    workers = changed_files.select { |f| f.start_with?('app/workers/') }.map { |f| classify_string(File.basename(f, '.rb')) }
    
    # Add changed files with impact level
    mermaid << "    subgraph \"Changed Files\"\n"
    changed_files.each do |file|
      impact_level = calculate_file_impact(file)
      impact_class = case impact_level
                     when 'high'
                       "highImpact"
                     when 'medium'
                       "mediumImpact"
                     else
                       "lowImpact"
                     end
      mermaid << "      #{file.gsub(/[^a-zA-Z0-9]/, '_')}[#{File.basename(file)}<br/>#{impact_level} impact]:::#{impact_class}\n"
    end
    mermaid << "    end\n\n"
    
    # Add affected components with dependency info
    if models.any?
      mermaid << "    subgraph \"Affected Models\"\n"
      models.each do |model|
        data = @models[model]
        if data
          dependency_count = data[:dependencies].size
          association_count = data[:associations].size
          mermaid << "      #{model}[#{model}<br/>#{dependency_count} deps, #{association_count} assoc]\n"
        else
          mermaid << "      #{model}[#{model}]\n"
        end
      end
      mermaid << "    end\n\n"
    end
    
    if controllers.any?
      mermaid << "    subgraph \"Affected Controllers\"\n"
      controllers.each do |controller|
        data = @controllers[controller]
        if data
          dependency_count = data[:dependencies].size
          action_count = data[:actions].size
          mermaid << "      #{controller}[#{controller}<br/>#{dependency_count} deps, #{action_count} actions]\n"
        else
          mermaid << "      #{controller}[#{controller}]\n"
        end
      end
      mermaid << "    end\n\n"
    end
    
    if services.any?
      mermaid << "    subgraph \"Affected Services\"\n"
      services.each do |service|
        data = @services[service]
        if data
          dependency_count = data[:dependencies].size
          mermaid << "      #{service}[#{service}<br/>#{dependency_count} deps]\n"
        else
          mermaid << "      #{service}[#{service}]\n"
        end
      end
      mermaid << "    end\n\n"
    end
    
    if workers.any?
      mermaid << "    subgraph \"Affected Workers\"\n"
      workers.each do |worker|
        data = @workers[worker]
        if data
          dependency_count = data[:dependencies].size
          mermaid << "      #{worker}[#{worker}<br/>#{dependency_count} deps]\n"
        else
          mermaid << "      #{worker}[#{worker}]\n"
        end
      end
      mermaid << "    end\n\n"
    end
    
    mermaid << "  end\n\n"
    
    # Add detailed relationships
    mermaid << "  %% Direct file changes\n"
    changed_files.each do |file|
      case file
      when /app\/models\/(.+)\.rb$/
        model_name = classify_string($1)
        mermaid << "  #{file.gsub(/[^a-zA-Z0-9]/, '_')} --> #{model_name}\n"
      when /app\/controllers\/(.+)\.rb$/
        controller_name = classify_string($1)
        mermaid << "  #{file.gsub(/[^a-zA-Z0-9]/, '_')} --> #{controller_name}\n"
      when /app\/services\/(.+)\.rb$/
        service_name = classify_string($1)
        mermaid << "  #{file.gsub(/[^a-zA-Z0-9]/, '_')} --> #{service_name}\n"
      when /app\/workers\/(.+)\.rb$/
        worker_name = classify_string($1)
        mermaid << "  #{file.gsub(/[^a-zA-Z0-9]/, '_')} --> #{worker_name}\n"
      end
    end
    
    # Add dependency relationships between affected components
    mermaid << "  %% Dependency relationships\n"
    models.each do |model|
      data = @models[model]
      if data
        data[:dependencies].each do |dep|
          if models.include?(dep) || controllers.include?(dep) || services.include?(dep)
            mermaid << "  #{model} -.-> #{dep}\n"
          end
        end
      end
    end
    
    controllers.each do |controller|
      data = @controllers[controller]
      if data
        data[:dependencies].each do |dep|
          if models.include?(dep) || services.include?(dep)
            mermaid << "  #{controller} -.-> #{dep}\n"
          end
        end
      end
    end
    
    # Add class definitions for styling
    mermaid << "\n  classDef highImpact fill:#ff6666,stroke:#cc0000,stroke-width:2px\n"
    mermaid << "  classDef mediumImpact fill:#ffaa66,stroke:#cc6600,stroke-width:2px\n"
    mermaid << "  classDef lowImpact fill:#66ff66,stroke:#00cc00,stroke-width:2px\n"
    mermaid << "  classDef highComplexity fill:#ffcccc,stroke:#ff6666,stroke-width:2px\n"
    mermaid << "  classDef mediumComplexity fill:#ffffcc,stroke:#ffaa66,stroke-width:2px\n"
    mermaid << "  classDef lowComplexity fill:#ccffcc,stroke:#66ff66,stroke-width:2px\n"
    mermaid << "  classDef criticalRisk fill:#cc0000,stroke:#990000,stroke-width:3px,color:#ffffff\n"
    mermaid << "  classDef highRisk fill:#ff3333,stroke:#cc0000,stroke-width:2px\n"
    mermaid << "  classDef mediumRisk fill:#ffaa66,stroke:#cc6600,stroke-width:2px\n"
    mermaid << "  classDef lowRisk fill:#66ff66,stroke:#00cc00,stroke-width:2px\n"
    
    File.write("#{output_path}/reports/enhanced_pr_report.md", mermaid)
  end

  def generate_pr_risk_assessment_report(changed_files)
    content = String.new("# 🚨 PR Risk Assessment Report\n\n")
    
    # AI Risk Score Section
    if @pr_ai_risk_score
      content << "## 🤖 AI-Powered Risk Analysis\n\n"
      content << "**Overall Risk Score:** #{@pr_ai_risk_score[:score]}/100 (#{@pr_ai_risk_score[:level]})\n\n"
      
             content << "### Risk Factors:\n"
       @pr_ai_risk_score[:factors].each do |factor, value|
         content << "- **#{humanize_string(factor)}:** #{value}\n"
       end
      
      if @pr_ai_risk_score[:recommendations].any?
        content << "\n### 💡 AI Recommendations:\n"
        @pr_ai_risk_score[:recommendations].each do |rec|
          content << "- #{rec}\n"
        end
      end
      content << "\n---\n\n"
    end
    
    # Performance Risks
    if @pr_performance_risks&.any?
      content << "## ⚡ Performance Risks\n\n"
      @pr_performance_risks.each do |file, risks|
        content << "### #{file}\n"
        risks.each { |risk| content << "- ⚠️ #{risk}\n" }
        content << "\n"
      end
      content << "---\n\n"
    end
    
    # Security Risks
    if @pr_security_risks&.any?
      content << "## 🔒 Security Risks\n\n"
      @pr_security_risks.each do |file, risks|
        content << "### #{file}\n"
        risks.each { |risk| content << "- 🛡️ #{risk}\n" }
        content << "\n"
      end
      content << "---\n\n"
    end
    
    # Database Impact
    if @pr_database_impacts&.any?
      content << "## 🗄️ Database Impact\n\n"
      @pr_database_impacts.each do |file, impacts|
        content << "### #{file}\n"
        impacts.each { |impact| content << "- 💾 #{impact}\n" }
        content << "\n"
      end
      content << "---\n\n"
    end
    
    # Test Impact
    if @pr_test_impacts&.any?
      content << "## 🧪 Test Coverage Impact\n\n"
      @pr_test_impacts.each do |file, impact|
        content << "- **#{file}:** #{impact}\n"
      end
      content << "\n"
    end
    
    File.write("#{output_path}/reports/pr_risk_assessment.md", content)
  end

  def generate_pr_impact_summary_report(changed_files)
    content = String.new("# 📊 PR Impact Summary\n\n")
    
    content << "## 📈 Change Statistics\n\n"
    content << "| Metric | Count |\n"
    content << "|--------|-------|\n"
    content << "| Total Files Changed | #{changed_files.size} |\n"
    content << "| Models Modified | #{changed_files.count { |f| f.include?('models/') }} |\n"
    content << "| Controllers Modified | #{changed_files.count { |f| f.include?('controllers/') }} |\n"
    content << "| Services Modified | #{changed_files.count { |f| f.include?('services/') }} |\n"
    content << "| Workers Modified | #{changed_files.count { |f| f.include?('workers/') }} |\n"
    content << "| Test Files Modified | #{changed_files.count { |f| f.include?('spec/') || f.include?('test/') }} |\n"
    
    content << "\n## 🎯 Impact Areas\n\n"
    
    # Categorize impact by domain
    domains = analyze_impact_by_domain(changed_files)
    domains.each do |domain, files|
      content << "### #{domain}\n"
      files.each { |file| content << "- `#{file}`\n" }
      content << "\n"
    end
    
    # Risk level summary
    if @pr_ai_risk_score
      content << "## 🚦 Risk Level Summary\n\n"
      case @pr_ai_risk_score[:level]
      when "Critical"
        content << "🔴 **CRITICAL RISK** - This PR requires immediate attention and thorough review.\n\n"
      when "High"
        content << "🟠 **HIGH RISK** - Proceed with caution and ensure comprehensive testing.\n\n"
      when "Medium"
        content << "🟡 **MEDIUM RISK** - Standard review process recommended.\n\n"
      else
        content << "🟢 **LOW RISK** - Low impact changes, routine review sufficient.\n\n"
      end
    end
    
    File.write("#{output_path}/reports/pr_impact_summary.md", content)
  end

  def analyze_impact_by_domain(changed_files)
    domains = {
      'User Management' => [],
      'Document Handling' => [],
      'Business Logic' => [],
      'Background Processing' => [],
      'API/Controllers' => [],
      'Testing' => [],
      'Other' => []
    }
    
    changed_files.each do |file|
      case file
      when /user|contact|firm|lawyer|client/i
        domains['User Management'] << file
      when /document|file|attachment/i
        domains['Document Handling'] << file
      when /service/i
        domains['Business Logic'] << file
      when /worker|job/i
        domains['Background Processing'] << file
      when /controller/i
        domains['API/Controllers'] << file
      when /spec|test/i
        domains['Testing'] << file
      else
        domains['Other'] << file
      end
    end
    
    domains.reject { |_, files| files.empty? }
  end

  def generate_exportable_reports(changed_files)
    # Generate JSON export for API consumption
    json_data = {
      timestamp: Time.now.strftime("%Y-%m-%dT%H:%M:%S%z"),
      changed_files: changed_files,
      ai_risk_score: @pr_ai_risk_score,
      performance_risks: @pr_performance_risks,
      security_risks: @pr_security_risks,
      database_impacts: @pr_database_impacts,
      test_impacts: @pr_test_impacts,
      complexity_scores: @complexity_scores,
      summary: {
        total_files: changed_files.size,
        risk_level: @pr_ai_risk_score&.dig(:level) || "Unknown",
        has_security_risks: @pr_security_risks&.any? || false,
        has_performance_risks: @pr_performance_risks&.any? || false,
        has_db_impacts: @pr_database_impacts&.any? || false
      }
    }
    
    File.write("#{output_path}/reports/pr_analysis.json", JSON.pretty_generate(json_data))
    
    # Generate HTML report
    generate_html_report(changed_files, json_data)
    
    # Generate GitHub comment format
    generate_github_comment_format(changed_files)
  end

  def generate_html_report(changed_files, data)
    html_content = <<~HTML
      <!DOCTYPE html>
      <html lang="en">
      <head>
          <meta charset="UTF-8">
          <meta name="viewport" content="width=device-width, initial-scale=1.0">
          <title>PR Analysis Report</title>
          <style>
              body { font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', sans-serif; margin: 40px; line-height: 1.6; }
              .header { background: linear-gradient(135deg, #667eea 0%, #764ba2 100%); color: white; padding: 20px; border-radius: 8px; margin-bottom: 20px; }
              .risk-score { font-size: 2em; font-weight: bold; }
              .risk-critical { color: #dc3545; }
              .risk-high { color: #fd7e14; }
              .risk-medium { color: #ffc107; }
              .risk-low { color: #28a745; }
              .section { background: #f8f9fa; padding: 20px; margin: 20px 0; border-radius: 8px; border-left: 4px solid #007bff; }
              .file-list { list-style: none; padding: 0; }
              .file-item { background: white; margin: 5px 0; padding: 10px; border-radius: 4px; border-left: 3px solid #007bff; }
              .recommendations { background: #e7f3ff; border-left: 4px solid #0066cc; }
              table { width: 100%; border-collapse: collapse; margin: 20px 0; }
              th, td { border: 1px solid #ddd; padding: 12px; text-align: left; }
              th { background-color: #f2f2f2; }
          </style>
      </head>
      <body>
          <div class="header">
              <h1>🔍 PR Analysis Report</h1>
              <p>Generated on #{Time.now.strftime("%B %d, %Y at %I:%M %p")}</p>
          </div>
    HTML
    
    if data[:ai_risk_score]
      risk_class = "risk-#{data[:ai_risk_score][:level].downcase}"
      html_content << <<~HTML
        <div class="section">
            <h2>🤖 AI Risk Assessment</h2>
            <div class="risk-score #{risk_class}">
                Risk Score: #{data[:ai_risk_score][:score]}/100 (#{data[:ai_risk_score][:level]})
            </div>
            #{data[:ai_risk_score][:recommendations].any? ? 
              "<div class='recommendations'><h3>💡 Recommendations:</h3><ul>#{data[:ai_risk_score][:recommendations].map { |r| "<li>#{r}</li>" }.join}</ul></div>" : ""}
        </div>
      HTML
    end
    
    html_content << <<~HTML
      <div class="section">
          <h2>📊 Change Summary</h2>
          <table>
              <tr><th>Metric</th><th>Count</th></tr>
              <tr><td>Total Files Changed</td><td>#{data[:changed_files].size}</td></tr>
              <tr><td>Models Modified</td><td>#{data[:changed_files].count { |f| f.include?('models/') }}</td></tr>
              <tr><td>Controllers Modified</td><td>#{data[:changed_files].count { |f| f.include?('controllers/') }}</td></tr>
              <tr><td>Services Modified</td><td>#{data[:changed_files].count { |f| f.include?('services/') }}</td></tr>
          </table>
      </div>

      <div class="section">
          <h2>📝 Changed Files</h2>
          <ul class="file-list">
              #{data[:changed_files].map { |file| "<li class='file-item'>#{file}</li>" }.join}
          </ul>
      </div>
      </body>
      </html>
    HTML
    
    File.write("#{output_path}/reports/pr_analysis_report.html", html_content)
  end

  def generate_github_comment_format(changed_files)
    content = String.new("## 🔍 Automated PR Analysis\n\n")
    
    content << "### 🟡 Risk Assessment\n"
    content << "**AI Risk Score:** #{@pr_ai_risk_score[:score]}/100 (#{@pr_ai_risk_score[:level]})\n\n"
    
    if @pr_ai_risk_score[:recommendations] && @pr_ai_risk_score[:recommendations].any?
      content << "**Recommendations:**\n"
      @pr_ai_risk_score[:recommendations].each { |rec| content << "- #{rec}\n" }
      content << "\n"
    end

    # Enhanced commit progression section
    if @commit_analyses && @commit_analyses.any?
      content << "### 📈 Commit Progression Analysis\n\n"
      
      # Timeline diagram
      content << "<details>\n<summary>🗓️ <strong>Timeline Overview</strong></summary>\n\n"
      content << "```mermaid\n"
      content << File.read("docs/system-diagrams/reports/pr_timeline.md") if File.exist?("docs/system-diagrams/reports/pr_timeline.md")
      content << "\n```\n\n"
      content << "</details>\n\n"
      
      # Individual commit visuals
      @commit_analyses.each_with_index do |commit_analysis, index|
        commit_number = index + 1
        commit_sha_short = commit_analysis[:sha][0..7]
        
        content << "<details>\n"
        content << "<summary>📝 <strong>Commit #{commit_number}: #{commit_sha_short}</strong> - #{commit_analysis[:message]}</summary>\n\n"
        
        # Commit summary info
        content << "**Impact Score:** #{commit_analysis[:impact_score]}/100\n"
        content << "**Files Changed:** #{commit_analysis[:changed_files].size}\n"
        
        if commit_analysis[:risks].any?
          content << "**Risk Categories:** #{commit_analysis[:risks].join(', ')}\n"
        end
        content << "\n"
        
        # Embed the commit diagram directly
        commit_diagram_file = "docs/system-diagrams/commits/commit_#{commit_number}_#{commit_sha_short}.md"
        if File.exist?(commit_diagram_file)
          content << "```mermaid\n"
          content << File.read(commit_diagram_file)
          content << "\n```\n\n"
        end
        
        # Add risk details if any
        if commit_analysis[:security_risks] > 0
          content << "🔒 **Security Issues:** #{commit_analysis[:security_risks]}\n"
        end
        if commit_analysis[:performance_risks] > 0
          content << "⚡ **Performance Issues:** #{commit_analysis[:performance_risks]}\n"
        end
        if commit_analysis[:database_risks] > 0
          content << "🗄️ **Database Issues:** #{commit_analysis[:database_risks]}\n"
        end
        if commit_analysis[:test_coverage_risks] > 0
          content << "🧪 **Test Coverage Issues:** #{commit_analysis[:test_coverage_risks]}\n"
        end
        
        content << "\n</details>\n\n"
      end
    end

    content << "### 📊 Change Statistics\n"
    content << "- **Files Changed:** #{(@changed_files || []).size}\n"
    content << "- **Models:** #{(@changed_files || []).count { |f| f.include?('models/') }}\n"
    content << "- **Controllers:** #{(@changed_files || []).count { |f| f.include?('controllers/') }}\n"
    content << "- **Services:** #{(@changed_files || []).count { |f| f.include?('services/') }}\n\n"

    content << "### ⚠️ Issues Found\n"
    content << "- **Performance Risks:** #{(@pr_performance_risks || {}).size}\n"
    content << "- **Security Risks:** #{(@pr_security_risks || {}).size}\n"
    content << "- **Database Impacts:** #{(@pr_database_impacts || {}).size}\n\n"

    content << "### 📋 Detailed Reports\n"
    content << "View the complete analysis in the generated reports:\n"
    content << "- [Risk Assessment](./docs/system-diagrams/reports/pr_risk_assessment.md)\n"
    content << "- [Impact Summary](./docs/system-diagrams/reports/pr_impact_summary.md)\n"
    content << "- [Visual Diagram](./docs/system-diagrams/reports/enhanced_pr_report.md)\n"
    content << "- [📈 Timeline Analysis](./docs/system-diagrams/reports/pr_timeline.md)\n"
    content << "- [📚 Commit Analysis Index](./docs/system-diagrams/commits/index.md)\n\n"

    content << "<details>\n<summary>🎯 View Overall Dependency Diagram</summary>\n\n"
    content << "```mermaid\n"
    content << generate_simple_pr_diagram_for_comment(changed_files)
    content << "```\n</details>\n\n"
    
    content << "---\n"
    content << "_Generated by System Visualizer at #{Time.now.strftime("%Y-%m-%d %H:%M:%S")}_"
    
    File.write("docs/system-diagrams/reports/github_comment.md", content)
    puts "✅ Enhanced GitHub comment format generated with embedded commit visuals!"
  end

  def generate_simple_pr_diagram_for_comment(changed_files)
    # Simple diagram for GitHub comment without recursion
    mermaid = String.new("")
    mermaid << "graph TD\n"
    mermaid << "  subgraph \"PR Summary\"\n"
    mermaid << "    PRInfo[\"📝 Pull Request<br/>#{changed_files.size} files changed<br/>Risk Score: #{@pr_ai_risk_score[:score]}/100\"]:::riskScore\n"
    
    if changed_files.any?
      mermaid << "    subgraph \"Changed Files\"\n"
      changed_files.each do |file|
        file_name = File.basename(file, '.rb')
        file_class = case file
                     when /models/ then "modelFile"
                     when /controllers/ then "controllerFile"
                     when /services/ then "serviceFile"
                     when /workers/ then "workerFile"
                     else "otherFile"
                     end
        mermaid << "      #{file_name.gsub(/[^a-zA-Z0-9]/, '_')}[#{file_name}]:::#{file_class}\n"
      end
      mermaid << "    end\n"
    end
    
    mermaid << "  end\n\n"
    
    # Add styling
    mermaid << "  classDef modelFile fill:#e1f5fe,stroke:#0277bd,stroke-width:2px\n"
    mermaid << "  classDef controllerFile fill:#f3e5f5,stroke:#7b1fa2,stroke-width:2px\n"
    mermaid << "  classDef serviceFile fill:#e8f5e8,stroke:#388e3c,stroke-width:2px\n"
    mermaid << "  classDef workerFile fill:#fff3e0,stroke:#f57c00,stroke-width:2px\n"
    mermaid << "  classDef riskScore fill:#ffeb3b,stroke:#f57f17,stroke-width:3px\n"
    
    mermaid
  end

  def generate_commit_reports(commit_analyses)
    return if commit_analyses.empty?
    
    puts "📊 Generating individual commit reports..."
    
    # Create commits directory
    commits_dir = "#{output_path}/commits"
    FileUtils.mkdir_p(commits_dir)
    
    commit_analyses.each_with_index do |analysis, index|
      commit = analysis[:commit]
      
      # Generate small diagram for this commit
      generate_commit_diagram(analysis, index + 1)
      
      # Generate commit summary
      generate_commit_summary(analysis, index + 1)
    end
    
    # Generate commit index
    generate_commit_index(commit_analyses)
  end

  def generate_commit_diagram(analysis, commit_number)
    sha_short = analysis[:sha][0..7]
    mermaid = String.new("")
    
    mermaid << "graph TD\n"
    mermaid << "  subgraph \"Commit #{commit_number}: #{sha_short}\"\n"
    
    # Add commit info
    risk_class = case analysis[:impact_score]
                 when 0..20 then "lowRisk"
                 when 21..50 then "mediumRisk"
                 when 51..80 then "highRisk"
                 else "criticalRisk"
                 end
    
    mermaid << "    CommitInfo[\"📝 #{sha_short}<br/>Impact: #{analysis[:impact_score]}/100<br/>Files: #{analysis[:changed_files].size}\"]:::#{risk_class}\n"
    
    # Add changed files
    if analysis[:changed_files].any?
      mermaid << "    subgraph \"Changed Files\"\n"
      analysis[:changed_files].each do |file|
        file_name = File.basename(file, '.rb')
        file_class = case file
                     when /models/ then "modelFile"
                     when /controllers/ then "controllerFile"
                     when /services/ then "serviceFile"
                     when /workers/ then "workerFile"
                     else "otherFile"
                     end
        mermaid << "      #{file_name.gsub(/[^a-zA-Z0-9]/, '_')}[#{file_name}]:::#{file_class}\n"
      end
      mermaid << "    end\n"
    end
    
    # Add risks if any
    if analysis[:security_risks] > 0
      mermaid << "    SecurityRisks[\"🔒 Security<br/>#{analysis[:security_risks]} issues\"]:::securityRisk\n"
      mermaid << "    CommitInfo --> SecurityRisks\n"
    end
    
    if analysis[:performance_risks] > 0
      mermaid << "    PerformanceRisks[\"⚡ Performance<br/>#{analysis[:performance_risks]} issues\"]:::performanceRisk\n"
      mermaid << "    CommitInfo --> PerformanceRisks\n"
    end
    
    if analysis[:database_risks] > 0
      mermaid << "    DatabaseRisks[\"🗄️ Database<br/>#{analysis[:database_risks]} issues\"]:::databaseRisk\n"
      mermaid << "    CommitInfo --> DatabaseRisks\n"
    end
    
    if analysis[:test_coverage_risks] > 0
      mermaid << "    Test_coverageRisks[\"🧪 Test Coverage<br/>#{analysis[:test_coverage_risks]} issues\"]:::test_coverageRisk\n"
      mermaid << "    CommitInfo --> Test_coverageRisks\n"
    end
    
    mermaid << "  end\n\n"
    
    # Add styling
    mermaid << "  classDef lowRisk fill:#ccffcc,stroke:#00cc00,stroke-width:2px\n"
    mermaid << "  classDef mediumRisk fill:#ffffcc,stroke:#ffaa00,stroke-width:2px\n"
    mermaid << "  classDef highRisk fill:#ffcccc,stroke:#ff6600,stroke-width:2px\n"
    mermaid << "  classDef criticalRisk fill:#ff6666,stroke:#cc0000,stroke-width:3px\n"
    mermaid << "  classDef modelFile fill:#e1f5fe,stroke:#0277bd,stroke-width:2px\n"
    mermaid << "  classDef controllerFile fill:#f3e5f5,stroke:#7b1fa2,stroke-width:2px\n"
    mermaid << "  classDef serviceFile fill:#e8f5e8,stroke:#388e3c,stroke-width:2px\n"
    mermaid << "  classDef workerFile fill:#fff3e0,stroke:#f57c00,stroke-width:2px\n"
    mermaid << "  classDef securityRisk fill:#ffebee,stroke:#d32f2f,stroke-width:2px\n"
    mermaid << "  classDef performanceRisk fill:#fff8e1,stroke:#ffa000,stroke-width:2px\n"
    mermaid << "  classDef databaseRisk fill:#e3f2fd,stroke:#1976d2,stroke-width:2px\n"
    mermaid << "  classDef test_coverageRisk fill:#f1f8e9,stroke:#689f38,stroke-width:2px\n"
    
    File.write("docs/system-diagrams/commits/commit_#{commit_number}_#{sha_short}.md", mermaid)
  end

  def generate_commit_summary(analysis, commit_number)
    sha_short = analysis[:sha][0..7]
    content = String.new("# 📝 Commit #{commit_number}: #{sha_short}\n\n")
    
    content << "## ℹ️ Commit Information\n\n"
    content << "- **SHA:** `#{analysis[:sha]}`\n"
    content << "- **Author:** #{analysis[:author]}\n"
    content << "- **Date:** #{analysis[:date]}\n"
    content << "- **Message:** #{analysis[:message]}\n"
    content << "- **Impact Score:** #{analysis[:impact_score]}/100\n"
    content << "- **Files Changed:** #{analysis[:changed_files].size}\n\n"
    
    if analysis[:changed_files].any?
      content << "## 📁 Changed Files\n\n"
      analysis[:changed_files].each do |file|
        content << "- `#{file}`\n"
      end
      content << "\n"
    end
    
    content << "## ⚠️ Risk Analysis\n\n"
    
    if analysis[:security_risks] > 0
      content << "### 🔒 Security (#{analysis[:security_risks]} issues)\n\n"
      content << "- SQL injection risk added\n\n"
    end
    
    if analysis[:performance_risks] > 0
      content << "### ⚡ Performance (#{analysis[:performance_risks]} issues)\n\n"
      content << "- Performance issues detected\n\n"
    end
    
    if analysis[:database_risks] > 0
      content << "### 🗄️ Database (#{analysis[:database_risks]} issues)\n\n"
      content << "- New association may need index\n\n"
    end
    
    if analysis[:test_coverage_risks] > 0
      content << "### 🧪 Test Coverage (#{analysis[:test_coverage_risks]} issues)\n\n"
      analysis[:changed_files].each do |file|
        file_name = File.basename(file, '.rb')
        content << "- No test file for #{file_name}.rb\n"
      end
      content << "\n"
    end
    
    if analysis[:dependencies].any?
      content << "## 🔗 Dependencies\n\n"
      analysis[:dependencies].each { |dep| content << "- #{dep}\n" }
      content << "\n"
    end
    
    File.write("docs/system-diagrams/commits/commit_#{commit_number}_#{sha_short}_summary.md", content)
  end

  def generate_commit_index(commit_analyses)
    content = String.new("# 📚 Commit Analysis Index\n\n")
    content << "This PR contains #{commit_analyses.size} commits with individual analysis.\n\n"
    
    # Summary table
    content << "## 📊 Summary\n\n"
    content << "| Commit | SHA | Impact | Security | Performance | Database | Files |\n"
    content << "|--------|-----|--------|----------|-------------|----------|-------|\n"
    
    commit_analyses.each_with_index do |analysis, index|
      sha_short = analysis[:sha][0..7]
      security_count = analysis[:security_risks] || 0
      performance_count = analysis[:performance_risks] || 0
      database_count = analysis[:database_risks] || 0
      
      content << "| #{index + 1} | `#{sha_short}` | #{analysis[:impact_score]}/100 | #{security_count} | #{performance_count} | #{database_count} | #{analysis[:changed_files].size} |\n"
    end
    content << "\n"
    
    # Individual commit links
    content << "## 📝 Individual Commit Analysis\n\n"
    commit_analyses.each_with_index do |analysis, index|
      sha_short = analysis[:sha][0..7]
      content << "### Commit #{index + 1}: #{sha_short} - #{analysis[:message]}\n\n"
      content << "- **Impact Score:** #{analysis[:impact_score]}/100\n"
      content << "- **Files Changed:** #{analysis[:changed_files].size}\n"
      content << "- **Risk Categories:** #{analysis[:risks].join(', ')}\n"
      content << "- **[View Diagram](./commit_#{index + 1}_#{sha_short}.md)**\n"
      content << "- **[View Summary](./commit_#{index + 1}_#{sha_short}_summary.md)**\n\n"
    end
    
    File.write("docs/system-diagrams/commits/index.md", content)
  end

  def generate_pr_timeline_analysis(commit_analyses)
    return if commit_analyses.empty?
    
    puts "📈 Generating PR timeline analysis..."
    
    # Timeline diagram showing risk progression
    mermaid = String.new("")
    mermaid << "graph LR\n"
    mermaid << "  subgraph \"PR Timeline: Risk Progression\"\n"
    
    # Add timeline nodes
    commit_analyses.each_with_index do |analysis, index|
      sha_short = analysis[:sha][0..7]
      
      risk_class = case analysis[:impact_score]
                   when 0..20 then "lowRisk"
                   when 21..50 then "mediumRisk"
                   when 51..80 then "highRisk"
                   else "criticalRisk"
                   end
      
      # Risk indicators
      security_indicator = analysis[:security_risks] > 0 ? "🔒" : ""
      performance_indicator = analysis[:performance_risks] > 0 ? "⚡" : ""
      database_indicator = analysis[:database_risks] > 0 ? "🗄️" : ""
      
      mermaid << "    C#{index + 1}[\"#{sha_short}<br/>Impact: #{analysis[:impact_score]}<br/>#{security_indicator}#{performance_indicator}#{database_indicator}\"]:::#{risk_class}\n"
      
      # Connect to next commit
      if index < commit_analyses.size - 1
        mermaid << "    C#{index + 1} --> C#{index + 2}\n"
      end
    end
    
    mermaid << "  end\n\n"
    
    # Cumulative risk chart
    mermaid << "  subgraph \"Cumulative Risk Analysis\"\n"
    
    total_security = 0
    total_performance = 0
    total_database = 0
    
    commit_analyses.each_with_index do |analysis, index|
      total_security += analysis[:security_risks] || 0
      total_performance += analysis[:performance_risks] || 0
      total_database += analysis[:database_risks] || 0
      
      if index == commit_analyses.size - 1 # Last commit
        mermaid << "    FinalRisks[\"Final State<br/>🔒 Security: #{total_security}<br/>⚡ Performance: #{total_performance}<br/>🗄️ Database: #{total_database}\"]:::finalState\n"
      end
    end
    
    mermaid << "  end\n\n"
    
    # Connect timeline to final state
    if commit_analyses.any?
      mermaid << "  C#{commit_analyses.size} --> FinalRisks\n"
    end
    
    # Add styling
    mermaid << "  classDef lowRisk fill:#ccffcc,stroke:#00cc00,stroke-width:2px\n"
    mermaid << "  classDef mediumRisk fill:#ffffcc,stroke:#ffaa00,stroke-width:2px\n"
    mermaid << "  classDef highRisk fill:#ffcccc,stroke:#ff6600,stroke-width:2px\n"
    mermaid << "  classDef criticalRisk fill:#ff6666,stroke:#cc0000,stroke-width:3px\n"
    mermaid << "  classDef finalState fill:#e1f5fe,stroke:#0277bd,stroke-width:3px\n"
    
    File.write("#{output_path}/reports/pr_timeline.md", mermaid)
    
    # Generate timeline summary report
    generate_timeline_summary(commit_analyses)
  end

  def generate_timeline_summary(commit_analyses)
    content = String.new("# 📈 PR Timeline Analysis\n\n")
    
    content << "## 🎯 Overview\n\n"
    content << "This PR progressed through #{commit_analyses.size} commits with varying risk levels.\n\n"
    
    # Risk progression table
    content << "## 📊 Risk Progression\n\n"
    content << "| Commit | Impact Score | Security Risks | Performance Risks | Database Risks | Total Risk Score |\n"
    content << "|--------|--------------|----------------|-------------------|----------------|------------------|\n"
    
    commit_analyses.each_with_index do |analysis, index|
      sha_short = analysis[:sha][0..7]
      security_count = analysis[:security_risks] || 0
      performance_count = analysis[:performance_risks] || 0
      database_count = analysis[:database_risks] || 0
      total_risks = security_count + performance_count + database_count
      
      content << "| #{index + 1} (#{sha_short}) | #{analysis[:impact_score]} | #{security_count} | #{performance_count} | #{database_count} | #{total_risks} |\n"
    end
    content << "\n"
    
    # Key insights
    content << "## 💡 Key Insights\n\n"
    
    highest_impact = commit_analyses.max_by { |a| a[:impact_score] }
    if highest_impact
      commit_num = commit_analyses.index(highest_impact) + 1
      sha_short = highest_impact[:sha][0..7]
      content << "- **Highest Impact Commit:** ##{commit_num} (`#{sha_short}`) with impact score #{highest_impact[:impact_score]}/100\n"
    end
    
    security_commits = commit_analyses.select { |a| (a[:security_risks] || 0) > 0 }
    if security_commits.any?
      content << "- **Security Risks Introduced:** #{security_commits.size} commits introduced security vulnerabilities\n"
    end
    
    performance_commits = commit_analyses.select { |a| (a[:performance_risks] || 0) > 0 }
    if performance_commits.any?
      content << "- **Performance Concerns:** #{performance_commits.size} commits introduced performance risks\n"
    end
    
    database_commits = commit_analyses.select { |a| (a[:database_risks] || 0) > 0 }
    if database_commits.any?
      content << "- **Database Impact:** #{database_commits.size} commits require database considerations\n"
    end
    
    content << "\n## 🎯 Recommendations\n\n"
    
    total_security_risks = commit_analyses.sum { |a| a[:security_risks] || 0 }
    total_performance_risks = commit_analyses.sum { |a| a[:performance_risks] || 0 }
    total_database_risks = commit_analyses.sum { |a| a[:database_risks] || 0 }
    
    if total_security_risks > 0
      content << "- 🔒 **Security Review Required:** #{total_security_risks} security issues detected across commits\n"
    end
    
    if total_performance_risks > 0
      content << "- ⚡ **Performance Testing Recommended:** #{total_performance_risks} performance concerns identified\n"
    end
    
    if total_database_risks > 0
      content << "- 🗄️ **Database Review Needed:** #{total_database_risks} database-related changes require attention\n"
    end
    
    if commit_analyses.any? { |a| (a[:test_coverage_risks] || 0) > 0 }
      content << "- 🧪 **Add Tests:** Multiple commits lack corresponding test coverage\n"
    end
    
    File.write("docs/system-diagrams/reports/pr_timeline_summary.md", content)
  end

  private

  def humanize_string(str)
    str.to_s.gsub('_', ' ').split.map(&:capitalize).join(' ')
  end
end 