FROM ruby:3.1.2

COPY . /src
WORKDIR /src

RUN bundle install

CMD ["bundle", "exec", "ruby", "main.rb"]
