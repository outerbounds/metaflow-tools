from metaflow import FlowSpec, step, Parameter, conda, conda_base, IncludeFile, card
import os

# Use the specified version of python for this flow.
@conda_base(python="3.7.3")
class CondaNoopFlow(FlowSpec):
    myfile = IncludeFile(
        'myfile',
        is_text=True,
        help='Just to test out IncludeFile',
        default=os.path.abspath(__file__))

    @card
    @conda(libraries={"pandas": "1.3.3"})
    @step
    def start(self):
        import pandas
        print("hi from start")
        self.next(self.a)

    @card
    @conda(libraries={"editdistance": "0.5.3", "pandas": "1.3.3"})
    @step
    def a(self):
        import editdistance
        import pandas
        print("hi from a")
        print("printing myfile...")
        print(self.myfile)
        self.next(self.end)

    @card
    @step
    def end(self):
        print("hi from end")


if __name__ == "__main__":
    CondaNoopFlow()
