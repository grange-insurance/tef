SimpleCov.profiles.define 'tef_basic' do

  # Don't need to track test code
  add_filter '/spec/'
  add_filter '/features/'
  add_filter '/testing/'

  #Ignore results that are older than 10 minutes
  merge_timeout 600
end
