variable "GO_VERSION" {
  default = "1.17"
}

target "_common" {
  args = {
    GO_VERSION = GO_VERSION
  }
}

target "image" {
  inherits = ["_common"]
  target = "full"
  platforms = [
    "linux/amd64",
    "linux/arm64",
  ]
}

target "image-slim" {
  inherits = ["_common"]
  target = "slim"
  platforms = [
    "linux/amd64",
    "linux/arm64",
  ]
}

target "image-local" {
  inherits = ["_common"]
  target = "full"
  output = ["type=docker"]
  tags = ["summerwind/actions-runner-controller:local"]
}

target "image-local-slim" {
  inherits = ["_common"]
  target = "slim"
  output = ["type=docker"]
  tags = ["summerwind/actions-runner-controller:local-slim"]
}

target "image-all" {
  inherits = ["_common"]
  platforms = [
    "linux/amd64",
    "linux/arm64",
  ]
}

target "artifact" {
  inherits = ["_common"]
  target = "artifact"
  output = ["./dist"]
}

target "artifact-slim" {
  inherits = ["_common"]
  target = "artifact-slim"
  output = ["./dist"]
}

target "artifact-trim" {
  inherits = ["_common"]
  target = "artifact-trim"
  output = ["./dist"]
}

target "artifact-all" {
  inherits = ["artifact-all"]
  target = "artifact-all"
  output = ["./dist"]
  platforms = [
    "linux/amd64",
    "linux/arm64",
  ]
}

target "full-amd64" {
  inherits = ["_common"]
  target = "artifact"
  output = ["./dist"]
  platforms = [
    "linux/amd64",
  ]
}

target "slim-amd64" {
  inherits = ["_common"]
  target = "artifact-slim"
  output = ["./dist"]
  platforms = [
    "linux/amd64",
  ]
}

target "full-arm64" {
  inherits = ["_common"]
  target = "artifact"
  output = ["./dist"]
  platforms = [
    "linux/arm64",
  ]
}

target "slim-arm64" {
  inherits = ["_common"]
  target = "artifact-slim"
  output = ["./dist"]
  platforms = [
    "linux/arm64",
  ]
}

target "trim-amd64" {
  inherits = ["_common"]
  target = "artifact-slim"
  output = ["./dist"]
  platforms = [
    "linux/amd64",
  ]
}

target "trim-arm64" {
  inherits = ["_common"]
  target = "artifact-trim"
  output = ["./dist"]
  platforms = [
    "linux/arm64",
  ]
}
