# Generated by jeweler
# DO NOT EDIT THIS FILE DIRECTLY
# Instead, edit Jeweler::Tasks in Rakefile, and run the gemspec command
# -*- encoding: utf-8 -*-

Gem::Specification.new do |s|
  s.name = %q{acts_as_list_ar}
  s.version = "0.1.0"

  s.required_rubygems_version = Gem::Requirement.new(">= 0") if s.respond_to? :required_rubygems_version=
  s.authors = ["Kristian Mandrup", "Others"]
  s.date = %q{2010-06-20}
  s.description = %q{Make your model acts as a list. This acts_as extension provides the capabilities for sorting and reordering a number of objects in a list.
      The class that has this specified needs to have a +position+ column defined as an integer on the mapped database table.}
  s.email = %q{kmandrup@gmail.com}
  s.extra_rdoc_files = [
    "LICENSE",
     "README.rdoc"
  ]
  s.files = [
    ".document",
     ".gitignore",
     "LICENSE",
     "Notes.txt",
     "README.rdoc",
     "Rakefile",
     "VERSION",
     "init.rb",
     "lib/acts_as_list_ar.rb",
     "lib/acts_as_list_ar/rails2.rb",
     "lib/acts_as_list_ar/rails3.rb",
     "spec/list_spec.rb",
     "spec/spec_helper.rb",
     "test/acts_as_list_test.rb",
     "test/list_w_string_ids_test.rb",
     "test/sub_list_test.rb",
     "test/test_helper.rb"
  ]
  s.homepage = %q{http://github.com/rails/acts_as_list}
  s.rdoc_options = ["--charset=UTF-8"]
  s.require_paths = ["lib"]
  s.rubygems_version = %q{1.3.7}
  s.summary = %q{Gem version of acts_as_list for Active Record with Rails 2 and 3 support}
  s.test_files = [
    "spec/list_spec.rb",
     "spec/spec_helper.rb",
     "test/acts_as_list_test.rb",
     "test/list_w_string_ids_test.rb",
     "test/sub_list_test.rb",
     "test/test_helper.rb"
  ]

  if s.respond_to? :specification_version then
    current_version = Gem::Specification::CURRENT_SPECIFICATION_VERSION
    s.specification_version = 3

    if Gem::Version.new(Gem::VERSION) >= Gem::Version.new('1.2.0') then
      s.add_runtime_dependency(%q<activerecord>, [">= 1.15.4.7794"])
    else
      s.add_dependency(%q<activerecord>, [">= 1.15.4.7794"])
    end
  else
    s.add_dependency(%q<activerecord>, [">= 1.15.4.7794"])
  end
end

