module Jekyll

  # Represents a single archive page.
  class ArchivePage < Page

    class << self

      private_class_method :new

      # Generates an archive from a collection of posts.
      #
      # +:paginate_path+ must be of the form +some/relative/path/page:num/+,
      # where +:num+ will be replaced by the page number, starting from 2.
      #
      # To disable pagination, don't specify +:per_page+, or set it to +nil+.
      #
      # @see #initialize
      #
      # @param opts [Hash] the options to create the page with.
      #
      # @option opts [Site]                        :site                        the Jekyll site instance.
      # @option opts [String]                      :archive_id                  an identifier for the archive being generated.
      # @option opts [Hash{String => Array<Post>}] :archive_posts               the posts to generate the archive from.
      # @option opts [String]                      :base_dir                    a path relative to the source where the archive should be placed.
      # @option opts [String]                      :template_path               path to the layout template to use.
      # @option opts [String]                      :paginate_path ("page:num/") relative path where subsequent archive pages are placed.
      # @option opts [Integer]                     :per_page      (nil)         number of posts per page.
      #
      # @return [void]
      def generate(opts)
        # Get all arguments (throws an exception if an
        # argument is not present).
        site          = opts.fetch(:site)
        archive_id    = opts.fetch(:archive_id)
        archive_posts = opts.fetch(:archive_posts)
        base_dir      = opts.fetch(:base_dir)
        template_path = opts.fetch(:template_path)
        paginate_path = opts.fetch(:paginate_path, "page:num/")
        per_page      = opts.fetch(:per_page,      nil)

        # For each archive ID in the Hash...
        archive_posts.each do |page_id, posts|
          dir = archive_dir(base_dir, page_id)
          num_pages = calculate_pages(posts, per_page)

          # For each page number...
          (1..num_pages).each do |page_num|
            # Calculate the first and last posts
            if not per_page.nil?
              init = (page_num - 1) * per_page
              if (init + per_page - 1) >= posts.size
                offset = posts.size
              else
                offset = init + per_page - 1
              end
            else
              # If per_page is nil, just put all the posts on the page.
              init   = 0
              offset = posts.size - 1
            end

            # Calculate the previous and next pages
            previous_page      = page_num != 1 ? page_num - 1 : nil
            previous_page_path = page_num_to_path(previous_page, dir, paginate_path)
            next_page      = page_num != num_pages ? page_num + 1 : nil
            next_page_path = page_num_to_path(next_page, dir, paginate_path)

            current_page_path = page_num_to_path(page_num, dir, paginate_path)

            page_opts = {
              # General page options
              archive_id: archive_id,
              page_id:    page_id,

              # Pagination options
              page:               page_num,
              per_page:           per_page,
              posts:              posts[init..offset],
              total_posts:        posts.size,
              total_pages:        num_pages,
              previous_page:      previous_page,
              previous_page_path: previous_page_path,
              next_page:          next_page,
              next_page_path:     next_page_path
            }

            site.pages << self.new(site, current_page_path, "index.html", template_path, page_opts)
          end
        end
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

      # Calculates the total number of paginated pages.
      #
      # @param all_posts [Array<Post>] the posts.
      # @param per_page  [Integer]     posts per page.
      #
      # @return [Integer] the number of pages.
      def calculate_pages(all_posts, per_page)
        return 1 if per_page.nil?
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
      def ensure_leading_slash(path)
        path[0..0] == "/" ? path : "/#{path}"
      end

      # Returns the path for the given page number.
      #
      # @param page_num        [Integer] the page number.
      # @param pagination_base [String]  pagination base path (location
      #                                  of the first page).
      # @param paginate_path   [String]  path template for constructing
      #                                  subsequent page paths.
      #
      # @return [String] if the method succeeded.
      # @return [nil]    if +page_num+ was nil.
      def page_num_to_path(page_num, pagination_base, paginate_path)
        return nil if page_num.nil?

        path = pagination_base
        if page_num > 1
          path = File.join(path, paginate_path.sub(":num", page_num.to_s))
        end

        ensure_leading_slash(path)
      end

    end

    # Initializes a new ArchivePage instance.
    #
    # The first page will be placed at +#{dir}/index.html+, and subsequent
    # pages will be placed at +#{dir}/#{processed_paginate_path}/index.html+,
    # where +processed_paginate_path+ is the path of the current archive page.
    #
    # @param site          [Site]   the Jekyll site instance.
    # @param dir           [String] the path between the source and the file.
    # @param name          [String] the filename of the file.
    # @param template_path [String] path to the layout template to use.
    # @param opts          [Hash]   the options to create the page with.
    #
    # @option opts [String]      :archive_id         an identifier for the archive being generated.
    # @option opts [String]      :page_id            an identifier for the current archive page.
    # @option opts [Integer]     :page               the current page number.
    # @option opts [Integer]     :per_page           number of posts per page.
    # @option opts [Array<Post>] :posts              the posts to include in the page.
    # @option opts [Integer]     :total_posts        total number of posts.
    # @option opts [Integer]     :total_pages        total number of pages.
    # @option opts [Integer]     :previous_page      previous page number.
    # @option opts [String]      :previous_page_path previous page path.
    # @option opts [Integer]     :next_page          next page number.
    # @option opts [String]      :next_page_path     next page path.
    def initialize(site, dir, name, template_path, opts)
      # Initialize the superclass.
      @site = site
      @base = @site.source
      @dir  = dir
      @name = name

      # Process the name
      self.process(@name)

      @page_opts = opts

      # Read and parse the template
      template_dir = File.dirname(template_path)
      template     = File.basename(template_path)
      self.read_yaml(template_dir, template)
    end

    # Convert this ArchivePage's data to a Hash
    # suitable for use by Liquid.
    #
    # @return [Hash] the Hash representation of this ArchivePage.
    def to_liquid
      liquid = super

      @page_opts.each do |key, value|
        liquid[key.id2name] = value
      end

      return liquid
    end

  end

end
