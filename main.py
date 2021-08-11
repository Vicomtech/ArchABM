#!/usr/bin/env python3 

import typer
import json
from pathlib import Path
from archABM.engine import Engine

app = typer.Typer(name="archABM", help="ArchABM simulation helper")

@app.command()
def run(config_file: Path = typer.Argument(..., exists=True, help="The name of the configuration file"), 
        interactive: bool = typer.Option(False, "--interactive", "-i", prompt=False, help="Interactive CLI mode"), 
        save_log: bool = typer.Option(False, "--save-log", "-l", help="Save events logs"),
        save_config: bool = typer.Option(True, "--save-config", "-c", help="Save configuration file"),
        save_csv: bool = typer.Option(True, "--save-csv", "-t", help="Export results to csv format"),
        save_json: bool = typer.Option(False, "--save-json", "-j", help="Export results to json format"),
        return_output: bool = typer.Option(False, "--return-output", "-o", help="Return results dictionary")  
    ):
    """ArchABM simulation helper"""
    if config_file.is_file():
        with open(config_file, "r") as f:
            config = json.load(f)

        if interactive:
            save_log = typer.confirm("Save events logs", default=False)
            save_config = typer.confirm("Save configuration", default=True)
            save_csv = typer.confirm("Export to csv", default=True)
            save_json = typer.confirm("Export to json", default=False)
            return_output = typer.confirm("Return results", default=False)

        config["options"]["save_log"] = save_log
        config["options"]["save_config"] = save_config
        config["options"]["save_csv"] = save_csv
        config["options"]["save_json"] = save_json
        config["options"]["return_output"] = return_output
            
        typer.secho(f"Running archABM", fg=typer.colors.BLACK, bg=typer.colors.BRIGHT_GREEN)
        simulation = Engine(config)
        results = simulation.run()
    else:
        typer.secho(f"Not working", fg=typer.colors.WHITE, bg=typer.colors.RED, err=True)
        raise typer.Exit(code=1)


if __name__ == "__main__":
    app()