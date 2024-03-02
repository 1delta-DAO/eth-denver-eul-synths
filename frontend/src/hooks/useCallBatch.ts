import { useAccount, useClient, useWriteContract } from "wagmi"
import { evcAbi } from "../abis/EVC"
import { sepolia } from "viem/chains"
import { BalancerAdapter__factory, EVC__factory, MintableVault__factory } from "../abis/types"
import { COLLATERAL_VAULT, DEPLOYED_ADAPTER, DEPLOYED_EVC, MINTABLE_VAULT, PoolAsset, symbolToAsset } from "../constants"
import { parseUnits, zeroAddress } from 'viem'
import { waitForTransactionReceipt } from "viem/actions"

const useCallBatch = () => {

  const { writeContractAsync, isPending, isError, isSuccess } = useWriteContract()
  const client = useClient()

  if (!client) throw new Error('Client not found')
  const account = useAccount()

  if (!account) return () => null

  const caller = account.address ?? ''
  const recipient = caller;
  const balancerInterface = BalancerAdapter__factory.createInterface()
  const vaultInterface = MintableVault__factory.createInterface()
  const evcInterface = EVC__factory.createInterface()

  return async (depositAmount: number, borrowAmount: number, assetObj: PoolAsset) => {
    const symbol = assetObj.symbol
    const asset = symbolToAsset[symbol as keyof typeof symbolToAsset]
    if (!asset?.address) return;

    const callEvcEnableController = evcInterface.encodeFunctionData(
      'enableController',
      [
        caller,
        MINTABLE_VAULT
      ]
    )

    const callEvcEnableCollateral = evcInterface.encodeFunctionData(
      'enableCollateral',
      [
        caller,
        COLLATERAL_VAULT
      ]
    )

    const callVault = vaultInterface.encodeFunctionData('borrow', [
      parseUnits(borrowAmount.toString(), assetObj?.decimals ?? 18),
      DEPLOYED_ADAPTER
    ])
    const callBalancer = balancerInterface.encodeFunctionData('facilitateLeveragedDeposit', [
      asset.address, // address depositAsset,
      parseUnits(depositAmount.toString(), assetObj?.decimals ?? 18), // uint256 depositAmount,
      COLLATERAL_VAULT, // address vault,
      recipient // address recipient
    ])

    const items = [
      {
        targetContract: DEPLOYED_EVC,
        onBehalfOfAccount: zeroAddress,
        value: 0,
        data: callEvcEnableController
      },
      {
        targetContract: DEPLOYED_EVC,
        onBehalfOfAccount: zeroAddress,
        value: 0,
        data: callEvcEnableCollateral
      },
      {
        targetContract: MINTABLE_VAULT,
        onBehalfOfAccount: caller,
        value: 0,
        data: callVault
      },
      {
        targetContract: DEPLOYED_ADAPTER,
        onBehalfOfAccount: caller,
        value: 0,
        data: callBalancer
      }
    ]
    try {
      const hash = await writeContractAsync({
        abi: evcAbi,
        address: DEPLOYED_EVC,
        functionName: 'batch',
        chainId: sepolia.id,
        args: [
          items
        ],
      })
      await waitForTransactionReceipt(client, { hash })
    } catch (e: any) {
      console.error(e)
    }
  }
}

export default useCallBatch