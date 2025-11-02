import { live, LiveController } from "@camertron/live-component";

type UpdatePropsComponentProps = {
  mode: string
}

@live("UpdatePropsComponent")
export class UpdatePropsComponent extends LiveController<UpdatePropsComponentProps> {
  finish() {
    this.render((component) => {
      component.props.mode = "finish";
    });
  }
}
