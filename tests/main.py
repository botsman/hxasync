import asyncio

from tests import tests_Cases

cases = tests_Cases()
cases.execute()
asyncio.run(cases.execute())
