variable "GO_VERSION" {
  default = "1.17"
}

target "_common" {
  args = {
    GO_VERSION = GO_VERSION
  }
}

target "platform" {
  platforms = [
    "linux/amd64",
    "linux/arm64",
  ]
}
target "image-full-all" {
  inherits = ["_common", "platform"]
  target   = "full"
  platforms = [
    "linux/amd64",
    "linux/arm64",
  ]
}

target "image-trim-all" {
  inherits = ["_common", "platform"]
  target   = "slim"
  platforms = [
    "linux/amd64",
    "linux/arm64",
  ]
}

target "image-slim-all" {
  inherits = ["_common", "platform"]
  target   = "slim"
  platforms = [
    "linux/amd64",
    "linux/arm64",
  ]
}

target "artifact" {
  inherits = ["_common"]
  target   = "artifact"
  output   = ["./dist"]
}

target "artifact-slim" {
  inherits = ["_common"]
  target   = "artifact-slim"
  output   = ["./dist"]
}

target "artifact-trim" {
  inherits = ["_common"]
  target   = "artifact-trim"
  output   = ["./dist"]
}

target "artifact-all" {
  inherits = ["artifact-all"]
  target   = "artifact-all"
  output   = ["./dist"]
  platforms = [
    "linux/amd64",
    "linux/arm64",
  ]
}

target "full-amd64" {
  inherits = ["artifact"]
  platforms = [
    "linux/amd64",
  ]
}

target "trim-amd64" {
  inherits = ["artifact-trim"]
  platforms = [
    "linux/amd64",
  ]
}

target "slim-amd64" {
  inherits = ["artifact-slim"]
  platforms = [
    "linux/amd64",
  ]
}

target "full-arm64" {
  inherits = ["artifact"]
  platforms = [
    "linux/arm64",
  ]
}

target "trim-arm64" {
  inherits = ["artifact-trim"]
  platforms = [
    "linux/arm64",
  ]
}

target "slim-arm64" {
  inherits = ["artifact-slim"]
  platforms = [
    "linux/arm64",
  ]
}
