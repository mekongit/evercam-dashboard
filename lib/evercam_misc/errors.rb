# Copyright (c) 2014, Evercam.io

module Evercam
  class EvercamError < StandardError
    def initialize(message=nil, code=nil, status=400, *context)
      super(message)
      @status_code = status
      @code        = code
      @context     = [].concat(context)
    end

    attr_reader :status_code, :context

    def self.status_code
      400
    end

    def code
      if @code.nil?
        name  = self.class.name.split("::").last
        while !(match = /[A-Z]/.match(name)).nil?
          name.gsub!(match[0], "#{match.offset(0)[0] != 0 ? '_' : ''}#{match[0].downcase}")
        end
      else
        @code
      end
    end
  end

  class AuthenticationError < EvercamError
    def initialize(message=nil, code=nil, *context)
      super((message || "Unauthenticated"), code, self.class.status_code, *context)
    end

    def self.status_code
      401
    end
  end

  class AuthorizationError < EvercamError
    def initialize(message=nil, code=nil, *context)
      super((message || "Unauthorized"), code, self.class.status_code, *context)
    end

    def self.status_code
      403
    end
  end

  class NotFoundError < EvercamError
    def initialize(message=nil, code=nil, *context)
      super((message || "Not Found"), code, self.class.status_code, *context)
    end

    def self.status_code
      404
    end
  end

  class CameraOfflineError < EvercamError
    def initialize(message=nil, code=nil, *context)
      super((message || "Camera Offline"), code, self.class.status_code, *context)
    end

    def self.status_code
      503
    end
  end

  class OutcomeError < EvercamError
    def initialize(message=nil, code=nil, *context)
      super(message, code, self.class.status_code, *context)
    end

    def self.status_code
      400
    end
  end

  module WebErrors
    class BadRequestError < EvercamError
      def initialize(message=nil, code=nil, *context)
        super((message || "Bad Request"), code, self.class.status_code, *context)
      end

      def self.status_code
        400
      end
    end

    class ComingSoonError < EvercamError
      def initialize(message=nil, code=nil, *context)
        super((message || "Sorry, this method is not implemented yet."), code, self.class.status_code, *context)
      end

      def self.status_code
        501
      end
    end

    class ConflictError < EvercamError
      def initialize(message=nil, code=nil, *context)
        super((message || "Conflict"), code, self.class.status_code, *context)
      end

      def self.status_code
        409
      end
    end
  end
end
