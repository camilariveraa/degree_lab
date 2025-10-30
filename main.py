import asyncio

from pipelex.pipelex import Pipelex
from pipelex.pipeline.execute import execute_pipeline

async def main():
    # First, initialize Pipelex (this loads all pipeline definitions)
    Pipelex.make()

    # Execute the pipeline and wait for the result
    pipe_output = await execute_pipeline(
        pipe_code="44dmd",
        inputs={
            "description": {
                "concept": "Pipelex tutor",
                "content": "Help me learn how to use Pipelex",
            },
        },
    )

    # Get the final output
    tagline = pipe_output.main_stuff_as_str
    print(f"Generated tagline: {tagline}")

if __name__ == "__main__":
    asyncio.run(main())