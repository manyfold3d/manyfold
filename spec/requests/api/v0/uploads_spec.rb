require "swagger_helper"

# rubocop:disable RSpec/VariableName

describe "File Uploading", :after_first_run, :multiuser do # rubocop:disable RSpec/EmptyExampleGroup
  path "/upload" do
    options "Details of upload capabilities" do
      tags "File Uploading"
      description "Manyfold uses the Tus protocol for resumable uploading; see https://tus.io/protocols/resumable-upload for full details."
      produces Mime[:manyfold_api_v0].to_s
      security [client_credentials: ["upload"]]

      response "204", "Upload capabilities" do
        let(:Authorization) { "Bearer #{create(:oauth_access_token, scopes: "upload").plaintext_token}" }

        header "Tus-Resumable", schema: {
          type: :string,
          example: "1.0.0",
          description: "Tus protocol version"
        }
        header "Tus-Version", schema: {
          type: :string,
          example: "1.0.0,0.2.2,0.2.1",
          description: "Comma separated versions of the Tus protocol supported by the server"
        }
        header "Tus-Extension", schema: {
          type: :string,
          example: "creation,termination,expiration,concatenation",
          description: "Comma separated list of Tus protocol extensions supported by the server"
        }
        header "Tus-Max-Size", schema: {
          type: :integer,
          example: 1_073_741_824,
          description: "The maximum file size that can be uploaded to the server"
        }

        run_test!
      end
    end

    post "Create a new upload" do
      tags "File Uploading"
      description "Manyfold uses the Tus protocol for resumable uploading; see https://tus.io/protocols/resumable-upload for full details."
      produces Mime[:manyfold_api_v0].to_s

      parameter in: :header, name: "Tus-Resumable", description: "Tus protocol version", example: "1.0.0", required: true
      parameter in: :header, name: "Upload-Length", description: "Total size of upload, in bytes", example: 0, required: true
      parameter in: :header, name: "Upload-Metadata", description: "See https://tus.io/protocols/resumable-upload#upload-metadata", required: false
      security [client_credentials: ["upload"]]

      let(:"Tus-Resumable") { "1.0.0" }

      response "201", "Upload created successfully" do
        let(:"Upload-Length") { 10 }
        let(:Authorization) { "Bearer #{create(:oauth_access_token, scopes: "upload").plaintext_token}" }

        header "Location", schema: {
          type: :string,
          example: "/upload/24e533e02ec3bc40c387f1a0e460e216",
          description: "URL for the newly created upload"
        }

        run_test!
      end

      context "without upload scope" do
        response "403", "Forbidden" do
          let(:"Upload-Length") { 10 }
          let(:Authorization) { "Bearer #{create(:oauth_access_token, scopes: "").plaintext_token}" }

          run_test!
        end
      end

      context "without authentication details" do
        response "401", "Unauthorized" do
          let(:"Upload-Length") { 10 }
          let(:Authorization) { nil }

          run_test!
        end
      end
    end
  end

  path "/upload/{id}" do
    parameter in: :path, name: :id, example: "24e533e02ec3bc40c387f1a0e460e216"
    parameter in: :header, name: "Tus-Resumable", description: "Tus protocol version", example: "1.0.0", required: true

    let(:Authorization) { "Bearer #{create(:oauth_access_token, scopes: "upload").plaintext_token}" }
    let(:"Tus-Resumable") { "1.0.0" }
    let(:id) { "24e533e02ec3bc40c387f1a0e460e216" }

    around do |example|
      storage = Tus::Storage::Filesystem.new("tmp")
      Tus::Server.opts[:storage] = storage
      storage.create_file(id)
      storage.update_info(id, {"Upload-Length" => 1024, "Upload-Offset" => 384})
      example.run
      storage.delete_file(id)
    end

    head "Get status of upload" do
      tags "File Uploading"
      description "Manyfold uses the Tus protocol for resumable uploading; see https://tus.io/protocols/resumable-upload for full details."
      produces Mime[:manyfold_api_v0].to_s

      security [client_credentials: ["upload"]]

      response "204", "Upload status" do
        header "Tus-Resumable", schema: {
          type: :string,
          example: "1.0.0",
          description: "Tus protocol version"
        }
        header "Upload-Length", schema: {
          type: :integer,
          example: 1024,
          description: "The expected total length of the file to be uploaded"
        }
        header "Upload-Offset", schema: {
          type: :integer,
          example: 384,
          description: "The number of bytes of the file that have been uploaded so far"
        }

        run_test!
      end
    end

    patch "Upload bytes at specified offset" do
      tags "File Uploading"
      description "Manyfold uses the Tus protocol for resumable uploading; see https://tus.io/protocols/resumable-upload for full details."
      produces Mime[:manyfold_api_v0].to_s

      parameter in: :header, name: "Upload-Offset", description: "File offset for bytes being sent. Must be the same as current Upload-Offset value reported by the HEAD request.", example: 384, required: true
      parameter in: :header, name: "Content-Length", description: "The number of bytes being sent in the POST body", example: 128, required: true
      parameter in: :body, name: "bytes", required: true, schema: {type: :string, format: :byte}, example: "<binary data>"
      consumes "application/offset+octet-stream"
      security [client_credentials: ["upload"]]

      response "204", "Upload successful" do
        header "Upload-Offset", schema: {
          type: :integer,
          description: "The new upload offset after the uploaded bytes have been added",
          example: 512
        }

        let(:"Upload-Offset") { 384 }
        let(:"Content-Length") { 128 }
        let(:bytes) { SecureRandom.bytes(128) }

        run_test!
      end
    end
  end
end
# rubocop:enable RSpec/VariableName
