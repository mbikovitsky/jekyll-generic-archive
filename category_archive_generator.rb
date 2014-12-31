module Jekyll

  class CategoryArchiveGenerator < Generator

    def generate(site)
      template_path = File.join(site.source, '_layouts', 'category_index.html')
      
      opts = {
        site: site,
        archive_id: 'category',
        archive_posts: site.categories,
        base_dir: site.config.fetch("category_archive_base"),
        template_path: template_path
      }

      if site.config["category_archive_per_page"]
        opts[:per_page] = site.config["category_archive_per_page"].to_i
      end

      if site.config["category_archive_paginate_path"]
        opts[:paginate_path] = site.config["category_archive_paginate_path"]
      end

      if site.config["category_title_prefix"]
        opts[:title_prefix] = site.config["category_title_prefix"]
      end

      ArchivePage.generate(opts)
    end

  end

  module Filters

    # Outputs a list of categories as comma-separated <a> links. This is used
    # to output the category list for each post on a category page.
    #
    # This is adapted from +generate_categories.rb+
    # (https://github.com/recurser/jekyll-plugins).
    #
    # @param categories [Array<String>] the list of categories to format.
    #
    # @return [String]
    def category_links(categories)
      base_dir = @context.registers[:site].config["category_archive_base"]
      categories = categories.sort!.map do |category|
        category_dir = ArchivePage.archive_dir(base_dir, category)
        # Make sure the category directory begins with a slash.
        category_dir = "/#{category_dir}" unless category_dir =~ /^\//
        "<a class='category' href='#{category_dir}/'>#{category}</a>"
      end

      case categories.length
      when 0
        ""
      when 1
        categories[0].to_s
      else
        categories.join(", ")
      end
    end

  end

end
