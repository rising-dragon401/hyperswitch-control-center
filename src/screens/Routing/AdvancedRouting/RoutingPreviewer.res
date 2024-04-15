open RoutingTypes

module SimplePreview = {
  @react.component
  let make = (~gateways) => {
    let {globalUIConfig: {backgroundColor}} = React.useContext(ConfigContext.configContext)
    <UIUtils.RenderIf condition={gateways->Array.length > 0}>
      <div
        className="w-full mb-6 p-4 px-6 bg-white dark:bg-jp-gray-lightgray_background rounded-md border border-jp-gray-600 dark:border-jp-gray-850">
        <div
          className="flex flex-col mt-6 mb-4 rounded-md  border border-jp-gray-500 dark:border-jp-gray-960 divide-y divide-jp-gray-500 dark:divide-jp-gray-960">
          {gateways
          ->Array.mapWithIndex((item, i) => {
            <div
              className="h-12 flex flex-row items-center gap-4
             text-jp-gray-900 dark:text-jp-gray-text_darktheme px-3 ">
              <div
                className={`px-1.5 rounded-full ${backgroundColor} text-white font-semibold text-sm`}>
                {React.string(Int.toString(i + 1))}
              </div>
              <div> {React.string(item)} </div>
            </div>
          })
          ->React.array}
        </div>
      </div>
    </UIUtils.RenderIf>
  }
}

module GatewayView = {
  @react.component
  let make = (~gateways, ~connectorList=?) => {
    let {globalUIConfig: {font: {textColor}}} = React.useContext(ConfigContext.configContext)
    let getGatewayName = name => {
      switch connectorList {
      | Some(list) =>
        (list->ConnectorTableUtils.getConnectorObjectFromListViaId(name)).connector_label
      | None => name
      }
    }

    <div className="flex flex-wrap gap-4 items-center">
      {gateways
      ->Array.mapWithIndex((ruleGateway, index) => {
        <div
          key={Int.toString(index)}
          className={`my-2 h-6 md:h-8 flex items-center rounded-md border border-jp-gray-500 dark:border-jp-gray-960 font-medium ${textColor.primaryNormal} hover:${textColor.primaryNormal} bg-gradient-to-b from-jp-gray-250 to-jp-gray-200 dark:from-jp-gray-950 dark:to-jp-gray-950 focus:outline-none px-2 gap-1`}>
          {ruleGateway.gateway_name->getGatewayName->React.string}
          {if ruleGateway.distribution !== 100 {
            <span className="text-jp-gray-700 dark:text-jp-gray-600 ml-1">
              {(ruleGateway.distribution->Int.toString ++ "%")->React.string}
            </span>
          } else {
            React.null
          }}
        </div>
      })
      ->React.array}
    </div>
  }
}
