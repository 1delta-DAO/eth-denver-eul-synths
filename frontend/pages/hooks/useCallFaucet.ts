import { useAccount, useClient, useWriteContract } from "wagmi"
import { sepolia } from "viem/chains"
import { DEPLOYED_DEPLOYER, symbolToAsset } from "../src/constants"
import { waitForTransactionReceipt } from "viem/actions"
import { eulSynthsAbi } from "../src/abis/EulSynths"

export const useFaucet = () => {

  const { writeContractAsync, isPending, isError, isSuccess } = useWriteContract()
  const client = useClient()

  if (!client) throw new Error('Client not found')
  const account = useAccount()

  if (!account) return () => null

  return async (symbol: string) => {
    const asset = symbolToAsset(symbol)
    if (!asset?.address) return;

    try {
      const hash = await writeContractAsync({
        abi: eulSynthsAbi,
        address: DEPLOYED_DEPLOYER,
        functionName: 'faucet',
        chainId: sepolia.id,
        args: [
          asset.address as any
        ],
      })
      await waitForTransactionReceipt(client, { hash })
    } catch (e: any) {
      console.error(e)
    }
  }
}
