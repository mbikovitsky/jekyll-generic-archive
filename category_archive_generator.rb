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

end
