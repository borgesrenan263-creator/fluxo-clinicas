port ENV.fetch("PORT", 4567)
environment ENV.fetch("APP_ENV", "production")

workers ENV.fetch("WEB_CONCURRENCY", 0).to_i
threads_count = ENV.fetch("RAILS_MAX_THREADS", 5).to_i
threads threads_count, threads_count

preload_app! if ENV.fetch("WEB_CONCURRENCY", 0).to_i > 0
