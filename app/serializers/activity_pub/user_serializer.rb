module ActivityPub
  class UserSerializer < ApplicationSerializer
    def serialize
      {
        "@context": {
          f3di: "http://purl.org/f3di/ns#"
        },
        "f3di:concreteType": "User"
      }
    end
  end
end
