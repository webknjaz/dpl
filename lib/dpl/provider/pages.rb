module DPL
  class Provider
    class Pages < Provider
      """Implements Github Pages deployment

      Options:
        - repo [optional, for pushed to other repos]
        - github-token [required]
        - target-branch [optional, defaults to gh-pages]
        - keep-history [optional, defaults to false]
        - local-dir [optional, defaults to `pwd`]
        - fqdn [optional]
        - project-name [optional, defaults to fqdn or repo slug]
        - email [optional, defaults to deploy@travis-ci.org]
        - name [optional, defaults to Deployment Bot]
      """

      require 'tmpdir'

      experimental 'GitHub Pages'

      def initialize(context, options)
        super

        @build_dir = options[:local_dir] || '.'

        @project_name = options[:project_name] || fqdn || slug
        @gh_fqdn = fqdn

        @gh_ref = "github.com/#{slug}.git"
        @target_branch = options[:target_branch] || 'gh-pages'
        @gh_token = option(:github_token)
        @keep_history = !!keep_history

        @gh_email = options[:email] || 'deploy@travis-ci.org'
        @gh_name = "#{options[:name] || 'Deployment Bot'} (from Travis CI)"

        @gh_remote_url = "https://#{@gh_token}@#{@gh_ref}"
        @git_push_opts = @keep_history ? '' : ' --force'
      end

      def fqdn
        options.fetch(:fqdn) { nil }
      end

      def slug
        options.fetch(:repo) { context.env['TRAVIS_REPO_SLUG'] }
      end

      def keep_history
        options.fetch(:keep_history) { false }
      end

      def check_auth
      end

      def needs_key?
        false
      end

      def github_pull(target_dir)
        unless context.shell "git clone --quiet --branch='#{@target_branch}' --single-branch '#{@gh_remote_url}' '#{target_dir}' &>/dev/null"
          # if such branch doesn't exist at remote, do normal clone and create
          # a new orphan branch
          context.shell "git clone --quiet '#{@gh_remote_url}' '#{target_dir}' &>/dev/null"
          context.shell "git checkout --orphan '#{@target_branch}'"
        end
      end

      def github_clean
        context.shell "git ls-files -z | xargs -0 rm -f"  # remove all committed files from the repo
        context.shell "git ls-tree --name-only -d -r -z HEAD | sort -rz | xargs -0 rmdir"  # remove all directories from the repo
      end

      def github_init
        context.shell 'rm -rf .git'
        context.shell "git init" or raise 'Could not create new git repo'
        context.shell "git checkout --orphan '#{@target_branch}'" or raise 'Could not create new git repo'
      end

      def github_configure
        context.shell "git config user.email '#{@gh_email}'"
        context.shell "git config user.name '#{@gh_name}'"
      end

      def github_deploy
        context.shell "touch \"deployed at `date` by #{@gh_name}\""
        context.shell "echo '#{@gh_fqdn}' > CNAME" if @gh_fqdn
        context.shell 'git add -A .'
        context.shell "git commit -m 'Deploy #{@project_name} to #{@gh_ref}:#{@target_branch}'"
        context.shell "git push#{@git_push_opts} --quiet '#{@gh_remote_url}' '#{@target_branch}':'#{@target_branch}' &>/dev/null"
      end

      def push_app
        Dir.mktmpdir {|tmpdir|
            if @keep_history
              github_pull(tmpdir)
              FileUtils.cd(tmpdir, :verbose => true) do
                github_clean
              end
            end
            FileUtils.cp_r("#{@build_dir}/.", tmpdir)
            FileUtils.cd(tmpdir, :verbose => true) do
              unless @keep_history
                github_init
              end
              github_configure
              unless github_deploy
                error "Couldn't push the build to #{@gh_ref}:#{@target_branch}"
              end
            end
        }
      end

    end
  end
end
