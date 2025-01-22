BUILD_DIR := build
ARCHIVE_NAME := iw4-xenon-codjumper.zip

.PHONY: build-plugin
build-plugin:
	@echo "Building plugin"
	"C:\Windows\Microsoft.NET\Framework\v4.0.30319\MSBuild.exe" .\plugin\iw4-codjumper\iw4-codjumper.sln

.PHONY: archive
archive:
	@echo "Creating directory structure for release..."
	@if exist $(BUILD_DIR) rmdir /S /Q $(BUILD_DIR)
	@if exist $(ARCHIVE_NAME) del /Q $(ARCHIVE_NAME)

	@if not exist "$(BUILD_DIR)" mkdir "$(BUILD_DIR)"
	@xcopy mod $(BUILD_DIR)\mod /E /I
	@xcopy resources\plugins $(BUILD_DIR)\plugins /E /I
	@xcopy plugin\iw4-codjumper\build\Release\bin\iw4-codjumper.xex $(BUILD_DIR)\plugins\41560817 /E /I
	@echo "Creating archive..."

	@powershell Compress-Archive -Path "$(BUILD_DIR)\*" -DestinationPath $(ARCHIVE_NAME)
	@echo "Archive created: $(ARCHIVE_NAME)"

.PHONY: release
release: build-plugin archive
	@echo "Build and archive steps completed."
