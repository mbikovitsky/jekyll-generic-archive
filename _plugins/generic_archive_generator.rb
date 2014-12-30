module Jekyll

  # Represents a single archive page.
  class ArchivePage < Page

    # Initializes a new ArchivePage instance.
    #
    # @param opts [Hash] the options to create the page with.
    #
    # @option opts [Site]        :site                         the Jekyll site instance.
    # @option opts [String]      :dir                          the path between the source and the file.
    # @option opts [String]      :name          ("index.html") the filename of the file.
    # @option opts [String]      :template_path                path to the layout template to use.
    # @option opts [String]      :archive_id                   an identifier for the archive being generated.
    # @option opts [String]      :page_id                      an identifier for the current archive page.
    # @option opts [Array<Post>] :posts         ([])           the posts to include in the page.
    def initialize(opts)
      @site = opts.fetch(:site)
      @base = @site.source
      @dir  = opts.fetch(:dir)
      @name = opts.fetch(:name, "index.html")

      @archive_id = opts.fetch(:archive_id)
      @page_id    = opts.fetch(:page_id)
      @posts      = opts.fetch(:posts, [])

      self.process(@name)

      template_path = opts.fetch(:template_path)
      template_dir  = File.dirname(template_path)
      template      = File.basename(template_path)
      self.read_yaml(template_dir, template)
    end

    # Convert this ArchivePage's data to a Hash suitable for use by Liquid.
    #
    # @return [Hash] the Hash representation of this ArchivePage.
    def to_liquid
      additional = {
        "archive_id" => @archive_id,
        "page_id"    => @page_id,
        "posts"      => @posts
      }

      super.merge additional
    end

  end

  # Represents a single paginated archive page.
  class PaginatedArchivePage < ArchivePage

    # Calculates the total number of paginated pages.
    #
    # @param all_posts [Array<Post>] the posts.
    # @param per_page  [Integer]     posts per page.
    #
    # @return [Integer] the number of pages.
    def self.calculate_pages(all_posts, per_page)
      (all_posts.size.to_f / per_page.to_i).ceil
    end

    # Ensures the given path begins with a slash.
    #
    # If the path begins with a slash, it will be returned unchanged.
    # Otherwise, a slash will be prepended.
    #
    # @param path [String] the path
    #
    # @return [String]
    def self.ensure_leading_slash(path)
      path[0..0] == "/" ? path : "/#{path}"
    end

    # Initializes a new PaginatedArchivePage instance.
    #
    # +paginate_path+ must be of the form +some/relative/path/page:num/+,
    # where +:num+ will be replaced by the page number, starting from 2.
    #
    # The first page will be placed at +#{dir}/index.html+, and subsequent
    # pages will be placed at +#{dir}/#{processed_paginate_path}/index.html+,
    # where +processed_paginate_path+ is the path of the current archive page.
    #
    # @param (see ArchivePage#initialize)
    #
    # @option opts [String]  :paginate_path   path relative to +dir+ where subsequent
    #                                         archive pages are placed.
    # @option opts [Integer] :page_num        the current page number.
    # @option opts [Integer] :per_page        number of posts per page.
    # @option (see ArchivePage#initialize)
    def initialize(opts)
      # Initialize the superclass.
      super

      # Set instance variables.
      @paginate_path = opts.fetch(:paginate_path)
      @page          = opts.fetch(:page_num)
      @per_page      = opts.fetch(:per_page)

      # Set the total number of pages.
      @total_pages = self.class.calculate_pages(@posts, @per_page)

      # Check whether the page number given is valid.
      if @page > @total_pages
        raise RuntimeError, "page number can't be greater than total pages: #{@page} > #{@total_pages}"
      end

      # Save the original +@dir+ as the pagination base directory.
      @pagination_base = @dir

      # Set +@dir+ to the correct value (based on the current
      # page number).
      @dir = page_num_to_path(@page)

      # Calculate the first and last post indices.
      init = (@page - 1) * @per_page
      offset = (init + @per_page - 1) >= @posts.size ? @posts.size : (init + @per_page - 1)

      # Set the total number of posts.
      @total_posts = @posts.size

      # Set the posts for this page.
      @pager_posts = @posts[init..offset]

      # Set the previous page number and path.
      @previous_page = @page != 1 ? @page - 1 : nil
      @previous_page_path = page_num_to_path(@previous_page)

      # Set the next page number and path.
      @next_page = @page != @total_pages ? @page + 1 : nil
      @next_page_path = page_num_to_path(@next_page)
    end

    # Returns the path for the given page number.
    #
    # @param page_num [Integer] the page number.
    #
    # @return [String] if the method succeeded.
    # @return [nil]    if +page_num+ was nil.
    def page_num_to_path(page_num)
      return nil if page_num.nil?

      path = @pagination_base
      if page_num > 1
        path = File.join(path, @paginate_path.sub(":num", page_num.to_s))
      end

      self.class.ensure_leading_slash(path)
    end

    # Convert this PaginatedArchivePage's data to a Hash
    # suitable for use by Liquid.
    #
    # @return [Hash] the Hash representation of this PaginatedArchivePage.
    def to_liquid
      pager = {
        "page" => @page,
        "per_page" => @per_page,
        "posts" => @pager_posts,
        "total_posts" => @total_posts,
        "total_pages" => @total_pages,
        "previous_page" => @previous_page,
        "previous_page_path" => @previous_page_path,
        "next_page" => @next_page,
        "next_page_path" => @next_page_path
      }

      liquid = super
      liquid["archive_pager"] = pager

      liquid
    end

  end

  # Generates an archive from a collection of posts.
  class GenericArchiveGenerator

    # Initializes a new GenericArchiveGenerator instance.
    #
    # @param site          [Site]                        the Jekyll site instance.
    # @param archive_id    [String]                      an identifier for the archive being generated.
    # @param archive_posts [Hash{String => Array<Post>}] the posts to generate the archive from.
    # @param base_dir      [String]                      a path relative to the source where the archive should be placed.
    # @param template_path [String]                      path to the layout template to use.
    def initialize(site, archive_id, archive_posts, base_dir, template_path)
      @site          = site
      @archive_id    = archive_id
      @archive_posts = archive_posts
      @base_dir      = base_dir
      @template_path = template_path
    end

    # Creates a directory path for the given archive base and page ID.
    #
    # This is adapted from +generate_categories.rb+
    # (https://github.com/recurser/jekyll-plugins).
    #
    # @param archive_base [String] the archive base directory.
    # @param page_id      [String] an identifier for the archive page.
    #
    # @return [String] path with stripped leading and trailing slashes.
    def archive_dir(archive_base, page_id)
      archive_base = archive_base.gsub(/^\/*(.*)\/*$/, '\1')
      page_id = page_id.gsub(/_|\P{Word}/, '-').gsub(/-{2,}/, '-').downcase
      File.join(archive_base, page_id)
    end

    # Generates the archive.
    #
    # @return [void]
    def generate
      @archive_posts.each do |page_id, posts|
        opts = {
          site:          @site,
          dir:           archive_dir(@base_dir, page_id),
          name:          "index.html",
          template_path: @template_path,
          archive_id:    @archive_id,
          page_id:       page_id,
          posts:         posts
        }
        @site.pages << ArchivePage.new(opts)
      end
    end

  end

  # Generates a paginated archive from a collection of posts.
  class PaginatedGenericArchiveGenerator < GenericArchiveGenerator

    # Initializes a new PaginatedGenericArchiveGenerator instance.
    #
    # @param paginate_path [String]  path relative to +base_dir+ where
    #                                subsequent archive pages are placed.
    # @param per_page      [Integer] number of posts per page.
    # @param (see GenericArchiveGenerator#initialize)
    #
    # @see PaginatedArchivePage#initialize
    def initialize(paginate_path, per_page, *args)
      super(*args)

      @paginate_path = paginate_path
      @per_page = per_page
    end

    # (see GenericArchiveGenerator#generate)
    def generate
      @archive_posts.each do |page_id, posts|
        pages = PaginatedArchivePage.calculate_pages(posts, @per_page)
        (1..pages).each do |page_num|
          opts = {
            # General page options
            site:          @site,
            dir:           archive_dir(@base_dir, page_id),
            name:          "index.html",
            template_path: @template_path,
            archive_id:    @archive_id,
            page_id:       page_id,
            posts:         posts,

            # Pagination options
            paginate_path: @paginate_path,
            page_num:      page_num,
            per_page:      @per_page
          }
          @site.pages << PaginatedArchivePage.new(opts)
        end
      end
    end

  end

end
