.PHONY: bootstrap studio model-lab test app run-studio run-model-lab verify clean

bootstrap:
	swift --version

studio:
	swift build --configuration release --product AudiobookStudio

model-lab:
	swift build --configuration release --product AudiobookModelLab

test:
	swift test

app: studio model-lab
	BUILD_CONFIG=release Scripts/build-app.sh

run-studio:
	swift build --product AudiobookStudio
	BUILD_CONFIG=debug Scripts/build-app.sh
	open .build/dist/AudiobookStudio.app

run-model-lab:
	swift build --product AudiobookModelLab
	BUILD_CONFIG=debug Scripts/build-app.sh
	open .build/dist/AudiobookModelLab.app

verify:
	Scripts/verify-app.sh

clean:
	rm -rf .build
