@echo off
setlocal enabledelayedexpansion

set ALL_DIMS=subject_consistency background_consistency aesthetic_quality imaging_quality temporal_style overall_consistency human_action temporal_flickering motion_smoothness dynamic_degree
:: object_class multiple_objects needs perceptron2
:: appearance_style scene spatial_relationship color not supported for custom_input

:: Parse known bat-only flags; build PASS_ARGS without them for evaluate.py
set VIDEOS_PATH=
set OUTPUT_PATH=
set MODEL_PREFIX=
set PASS_ARGS=

:parseloop
if "%~1"=="" goto parsedone
if /i "%~1"=="--videos_path" (
    set VIDEOS_PATH=%~2
    set PASS_ARGS=!PASS_ARGS! %1 %2
    shift & shift & goto parseloop
)
if /i "%~1"=="--output_path" (
    set OUTPUT_PATH=%~2
    shift & shift & goto parseloop
)
if /i "%~1"=="--model" (
    set MODEL_PREFIX=%~2
    shift & shift & goto parseloop
)
if /i "%~1"=="--port" (
    set MASTER_PORT=%~2
    shift & shift & goto parseloop
)
set PASS_ARGS=!PASS_ARGS! %1
shift
goto parseloop
:parsedone

:: Get parent folder name of videos_path for subfolder + CSV prefix
set FOLDER_NAME=results
if defined VIDEOS_PATH (
    for %%F in ("!VIDEOS_PATH!") do set _PARENT=%%~dpF
    set _PARENT=!_PARENT:~0,-1!
    for %%F in ("!_PARENT!") do set FOLDER_NAME=%%~nxF
)

:: Default output_path to evaluation_results\[model_]<folder_name> subfolder
if defined MODEL_PREFIX (
    if not defined OUTPUT_PATH set OUTPUT_PATH=./evaluation_results/!MODEL_PREFIX!_!FOLDER_NAME!
) else (
    if not defined OUTPUT_PATH set OUTPUT_PATH=./evaluation_results/!FOLDER_NAME!
)

:: Default port
if not defined MASTER_PORT set MASTER_PORT=29501
set MASTER_PORT=!MASTER_PORT!

:: Inject --dimension ALL_DIMS if not already specified
echo.!PASS_ARGS! | findstr /i /c:"--dimension" >nul
if errorlevel 1 (
    python -c "import json,glob; done=sum([list(json.load(open(f)).keys()) for f in glob.glob(r'!OUTPUT_PATH!/*_eval_results.json')],[]); remaining=[d for d in '!ALL_DIMS!'.split() if d not in done]; print(' '.join(remaining))" > "%TEMP%\vbench_dims.txt" 2>nul
    set /p DIMS_TO_RUN=<"%TEMP%\vbench_dims.txt"
    if not defined DIMS_TO_RUN (
        echo All dimensions already completed.
        goto :postprocess
    )
    echo Skipping already completed dimensions. Running: !DIMS_TO_RUN!
    python evaluate.py !PASS_ARGS! --dimension !DIMS_TO_RUN! --mode custom_input --output_path "!OUTPUT_PATH!"
) else (
    python evaluate.py !PASS_ARGS! --mode custom_input --output_path "!OUTPUT_PATH!"
)

:postprocess
python write_csvs.py --output_path "!OUTPUT_PATH!" --prefix "!FOLDER_NAME!"

endlocal
