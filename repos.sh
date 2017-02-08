
RUBY_VER=2.2.5


echo "Cloning repos..."
# mkdir -p $HOME/Development/Docurated
# cd $HOME/Development/Docurated
# git clone git@github.com:Docurated/website.git
cd $HOME/Development/Docurated/website/rails
# echo $RUBY_VER@website > .ruby-version
gem install bundler

brew install imagemagick@6
brew link --force imagemagick@6
brew uninstall v8
gem install therubyracer -v '0.12.1'
brew install v8
gem install libv8 -v '3.16.14.7' -- --with-system-v8
bundle install

# git clone git@github.com:Docurated/activity.git
# git clone git@github.com:Docurated/flatutils.git
# git clone git@github.com:Docurated/utilities.git


# cd $HOME/Development/Docurated/utilities/docformation
# echo $RUBY_VER@utilities > .ruby-version

