variable "GO_VERSION" {
  default = "1.17"
}

variable "RUNNER_VERSION" {
}

variable "DOCKER_VERSION" {
  default = "20.10.8"
}

target "_common" {
  args = {
    GO_VERSION     = GO_VERSION
    RUNNER_VERSION = RUNNER_VERSION
    DOCKER_VERSION = DOCKER_VERSION
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
}

target "image-slim-all" {
  inherits = ["_common", "platform"]
  target   = "slim"
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

# Creating all full, slim artifact with arm and amd platform
target "artifact-all" {
  inherits = ["artifact-all", "platform"]
  target   = "artifact-all"
  output   = ["./dist"]
}
