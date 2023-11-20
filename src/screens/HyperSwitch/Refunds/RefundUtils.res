let getRefundsList = async (
  filterValueJson,
  ~updateDetails,
  ~setRefundsData,
  ~setScreenState,
  ~offset,
  ~setTotalCount,
  ~setOffset,
) => {
  open APIUtils
  open LogicUtils
  setScreenState(_ => PageLoaderWrapper.Loading)
  try {
    let refundsUrl = getURL(~entityName=REFUNDS, ~methodType=Post, ~id=Some("refund-post"), ())
    let res = await updateDetails(refundsUrl, filterValueJson->Js.Json.object_, Fetch.Post)
    let data = res->getDictFromJsonObject->getArrayFromDict("data", [])
    let total = res->getDictFromJsonObject->getInt("total_count", 0)

    let arr = Belt.Array.make(offset, Js.Dict.empty())
    if total <= offset {
      setOffset(_ => 0)
    }

    if total > 0 {
      let refundDataDictArr = data->Belt.Array.keepMap(Js.Json.decodeObject)
      let refundData =
        arr->Js.Array2.concat(refundDataDictArr)->Js.Array2.map(RefundEntity.itemToObjMapper)
      let list = refundData->Js.Array2.map(Js.Nullable.return)
      setRefundsData(_ => list)
      setTotalCount(_ => total)
      setScreenState(_ => PageLoaderWrapper.Success)
    } else {
      setScreenState(_ => Custom)
    }
  } catch {
  | _ => setScreenState(_ => Error("Failed to fetch"))
  }
}

let customUI =
  <HelperComponents.BluredTableComponent
    infoText="No refund records as of now. Try initiating a refund for a successful payment."
    buttonText="Take me to payments"
    onClickUrl="payments"
    moduleName=""
    mixPanelEventName="refunds_takemetopayments"
  />

let (startTimeFilterKey, endTimeFilterKey) = ("start_time", "end_time")

external toDict: 't => Js.Dict.t<Js.Json.t> = "%identity"
let filterByData = (txnArr, value) => {
  open LogicUtils
  let searchText = value->getStringFromJson("")

  txnArr
  ->Belt.Array.keepMap(Js.Nullable.toOption)
  ->Belt.Array.keepMap(data => {
    let valueArr =
      data
      ->toDict
      ->Js.Dict.entries
      ->Js.Array2.map(item => {
        let (_, value) = item

        value->getStringFromJson("")->Js.String2.toLowerCase->Js.String2.includes(searchText)
      })
      ->Array.reduce(false, (acc, item) => item || acc)

    valueArr ? data->Js.Nullable.return->Some : None
  })
}

let initialFixedFilter = () => [
  (
    {
      localFilter: None,
      field: FormRenderer.makeMultiInputFieldInfo(
        ~label="",
        ~comboCustomInput=InputFields.dateRangeField(
          ~startKey=startTimeFilterKey,
          ~endKey=endTimeFilterKey,
          ~format="YYYY-MM-DDTHH:mm:ss[Z]",
          ~showTime=false,
          ~disablePastDates={false},
          ~disableFutureDates={true},
          ~predefinedDays=[Today, Yesterday, Day(2.0), Day(7.0), Day(30.0), ThisMonth, LastMonth],
          ~numMonths=2,
          ~disableApply=false,
          ~dateRangeLimit=60,
          (),
        ),
        ~inputFields=[],
        ~isRequired=false,
        (),
      ),
    }: EntityType.initialFilters<'t>
  ),
]

let initialFilters = json => {
  open LogicUtils
  let filterDict = json->getDictFromJsonObject

  filterDict
  ->Js.Dict.keys
  ->Array.filterWithIndex((_item, index) => index <= 2)
  ->Js.Array2.map((key): EntityType.initialFilters<'t> => {
    let title = `Select ${key->snakeToTitle}`
    let values = filterDict->getArrayFromDict(key, [])->getStrArrayFromJsonArray

    {
      field: FormRenderer.makeFieldInfo(
        ~label="",
        ~name=key,
        ~customInput=InputFields.multiSelectInput(
          ~options=values->SelectBox.makeOptions,
          ~buttonText=title,
          ~showSelectionAsChips=false,
          ~searchable=true,
          ~showToolTip=true,
          ~showNameAsToolTip=true,
          ~customButtonStyle="bg-none",
          (),
        ),
        (),
      ),
      localFilter: Some(filterByData),
    }
  })
}
