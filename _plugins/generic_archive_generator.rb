module Jekyll

  # Represents a single archive page.
  class ArchivePage < Page

    # Initializes a new ArchivePage instance.
    #
    # @param site [Site] the Jekyll site instance.
    # @param base [String] the path to the source.
    # @param dir [String] the path between the source and the file.
    # @param name [String] the filename of the file.
    # @param template_path [String] path to the layout template to use.
    # @param archive_id [String] an identifier for the archive being generated.
    # @param page_id [String] an identifier for the current archive page.
    # @param posts [Array<Post>] the posts to include in the page.
    def initialize(site, base, dir, name, template_path, archive_id, page_id, posts)
      @site = site
      @base = base
      @dir  = dir
      @name = name

      self.process(@name)

      template_dir = File.dirname(template_path)
      template     = File.basename(template_path)
      self.read_yaml(template_dir, template)

      self.data["archive_id"] = archive_id
      self.data["page_id"]    = page_id
      self.data["posts"]      = posts
    end

  end

  # Generates an archive from a collection of posts.
  class GenericArchiveGenerator

    # Initializes a new GenericArchiveGenerator instance.
    #
    # @param site [Site] the Jekyll site instance.
    # @param archive_id [String] an identifier for the archive being generated.
    # @param archive_posts [Hash{String => Array<Post>}] the posts to generate the archive from.
    # @param base_dir [String] a path relative to the source where the archive should be placed.
    # @param template_path [String] path to the layout template to use.
    def initialize(site, archive_id, archive_posts, base_dir, template_path)
      @site          = site
      @archive_id    = archive_id
      @archive_posts = archive_posts
      @base_dir      = base_dir
      @template_path = template_path
    end

    # Generates the archive.
    #
    # @return [void]
    def generate
      @archive_posts.each do |page_id, posts|
        page = ArchivePage.new(@site, @site.source, @base_dir, "index.html", @template_path, @archive_id, page_id, posts)
        @site.pages << page
      end
    end

  end

end
