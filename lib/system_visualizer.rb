# frozen_string_literal: true

require 'fileutils'
require 'json'
require 'set'

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
  end

  def analyze
    puts "🔍 Analyzing Rails codebase..."
    
    analyze_models
    analyze_controllers
    analyze_services
    analyze_workers
    
    generate_diagrams
    puts "✅ Analysis complete! Diagrams saved to #{output_path}"
  end

  def analyze_pr_changes(base_branch = 'main')
    puts "🔍 Analyzing PR changes..."
    
    # Get changed files from git diff
    changed_files = get_changed_files(base_branch)
    
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
    
    generate_pr_diagram(changed_files)
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
        color = if dependency_count > 10
                  "style=\"fill:#ffcccc\""
                elsif dependency_count > 5
                  "style=\"fill:#ffffcc\""
                else
                  "style=\"fill:#ccffcc\""
                end
        
        mermaid << "    #{model_name}[#{model_name}<br/>#{association_count} assoc, #{dependency_count} deps]\n"
        mermaid << "    #{model_name} #{color}\n"
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
      color = if count > 20
                "style=\"fill:#ff6666\""
              elsif count > 10
                "style=\"fill:#ffaa66\""
              else
                "style=\"fill:#66ff66\""
              end
              mermaid << "      #{model_name}[#{model_name}<br/>#{count} references]\n"
        mermaid << "      #{model_name} #{color}\n"
    end
    mermaid << "    end\n"
    
    # Show models with most dependencies
    most_dependent = @models.sort_by { |_, data| data[:dependencies].size }.reverse.first(10)
    mermaid << "    subgraph \"Models with Most Dependencies\"\n"
    most_dependent.each do |model_name, data|
      color = if data[:dependencies].size > 15
                "style=\"fill:#ff6666\""
              elsif data[:dependencies].size > 8
                "style=\"fill:#ffaa66\""
              else
                "style=\"fill:#66ff66\""
              end
              mermaid << "      #{model_name}[#{model_name}<br/>#{data[:dependencies].size} deps]\n"
        mermaid << "      #{model_name} #{color}\n"
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
        
        color = if dependency_count > 8
                  "style=\"fill:#ffcccc\""
                elsif dependency_count > 4
                  "style=\"fill:#ffffcc\""
                else
                  "style=\"fill:#ccffcc\""
                end
        
        mermaid << "      #{service_name}[#{service_name}<br/>#{dependency_count} deps]\n"
        mermaid << "      #{service_name} #{color}\n"
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
      mermaid << "    NoCircular[No circular dependencies found]\n"
      mermaid << "    NoCircular style=\"fill:#ccffcc\"\n"
    end
    
    # Show high complexity areas
    high_complexity = find_high_complexity_areas
    mermaid << "    subgraph \"High Complexity Areas\"\n"
    high_complexity.each do |component, complexity_score|
      mermaid << "      #{component}[#{component}<br/>Complexity: #{complexity_score}]\n"
      mermaid << "      #{component} style=\"fill:#ffcccc\"\n"
    end
    mermaid << "    end\n"
    
    mermaid << "  end\n"
    
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
      color = case impact_level
              when 'high'
                "style=\"fill:#ff6666\""
              when 'medium'
                "style=\"fill:#ffaa66\""
              else
                "style=\"fill:#66ff66\""
              end
      mermaid << "      #{file.gsub(/[^a-zA-Z0-9]/, '_')}[#{File.basename(file)}<br/>#{impact_level} impact]\n"
      mermaid << "      #{file.gsub(/[^a-zA-Z0-9]/, '_')} #{color}\n"
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
end 