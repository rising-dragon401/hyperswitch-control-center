open PaymentAnalyticsEntity
open APIUtils
open HSAnalyticsUtils

@react.component
let make = () => {
  let (screenState, setScreenState) = React.useState(_ => PageLoaderWrapper.Loading)
  let (metrics, setMetrics) = React.useState(_ => [])
  let (dimensions, setDimensions) = React.useState(_ => [])
  let fetchDetails = useGetMethod()

  let loadInfo = async () => {
    open LogicUtils
    try {
      let infoUrl = getURL(~entityName=ANALYTICS_PAYMENTS, ~methodType=Get, ~id=Some(domain), ())
      let infoDetails = await fetchDetails(infoUrl)
      setMetrics(_ =>
        infoDetails
        ->getDictFromJsonObject
        ->getArrayFromDict("metrics", [])
        ->Js.Array2.filter(item => {
          let dict = item->LogicUtils.getDictFromJsonObject
          dict->Js.Dict.get("name")->Belt.Option.getWithDefault(""->Js.Json.string) !=
            "retries_count"->Js.Json.string
        })
      )
      setDimensions(_ => infoDetails->getDictFromJsonObject->getArrayFromDict("dimensions", []))
      setScreenState(_ => PageLoaderWrapper.Success)
    } catch {
    | Js.Exn.Error(e) =>
      let err = Js.Exn.message(e)->Belt.Option.getWithDefault("Failed to Fetch!")
      setScreenState(_ => PageLoaderWrapper.Error(err))
    }
  }
  let getPaymetsDetails = async () => {
    open LogicUtils
    try {
      setScreenState(_ => PageLoaderWrapper.Loading)
      let paymentUrl = getURL(~entityName=ORDERS, ~methodType=Get, ())
      let paymentDetails = await fetchDetails(paymentUrl)
      let data = paymentDetails->getDictFromJsonObject->getArrayFromDict("data", [])
      if data->Js.Array2.length < 0 {
        setScreenState(_ => PageLoaderWrapper.Custom)
      } else {
        await loadInfo()
      }
    } catch {
    | Js.Exn.Error(e) =>
      let err = Js.Exn.message(e)->Belt.Option.getWithDefault("Failed to Fetch!")
      setScreenState(_ => PageLoaderWrapper.Error(err))
    }
  }

  React.useEffect0(() => {
    getPaymetsDetails()->ignore
    None
  })

  let tabKeys = getStringListFromArrayDict(dimensions)

  let tabValues = tabKeys->Array.mapWithIndex((key, index) => {
    let a: DynamicTabs.tab = {
      title: key->LogicUtils.snakeToTitle,
      value: key,
      isRemovable: index > 2,
    }
    a
  })

  <PageLoaderWrapper screenState customUI={<NoData />}>
    <Analytics
      pageTitle="Payments Analytics"
      pageSubTitle="Gain Insights, monitor performance and make Informed Decisions with Payment Analytics."
      filterUri={`${HSwitchGlobalVars.hyperSwitchApiPrefix}/analytics/v1/filters/${domain}`}
      key="PaymentsAnalytics"
      moduleName="Payments"
      deltaMetrics={getStringListFromArrayDict(metrics)}
      chartEntity={default: chartEntity(tabKeys)}
      tabKeys
      tabValues
      options
      singleStatEntity={getSingleStatEntity(metrics)}
      getTable={getPaymentTable}
      colMapper
      tableEntity={paymentTableEntity}
      defaultSort="total_volume"
      deltaArray=[]
      tableUpdatedHeading=getUpdatedHeading
      tableGlobalFilter=filterByData
      startTimeFilterKey
      endTimeFilterKey
      initialFilters=initialFilterFields
      initialFixedFilters=initialFixedFilterFields
      weeklyTableMetricsCols
      distributionArray={[distribution]->Some}
    />
  </PageLoaderWrapper>
}
