import { useClient, useWriteContract } from "wagmi"
import { evcAbi } from "../src/abis/EVC"
import { sepolia } from "viem/chains"

export const useCallBatch = () => {

  const { writeContractAsync, isPending, isError, isSuccess } = useWriteContract()
  const client = useClient()

  if (!client) throw new Error('Client not found')
  
  const approve = async (spender: `0x${string}`, amount: number) => {
    const hash = await writeContractAsync({
      abi: evcAbi,
      address: "0xA347d56A33Ea46E8dCAF2Ce2De57087f8f171Bd6",
      functionName: 'batch',
      chainId: sepolia.id,
      args: [
        
      ],
    })
  }
}
