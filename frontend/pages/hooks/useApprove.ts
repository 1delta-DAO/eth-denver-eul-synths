import { useAccount, useReadContract, useWriteContract } from "wagmi"
import { approveAndAllowanceAbi, symbolToAsset } from "../src/constants"
import { sepolia } from "viem/chains"
import { getTransaction } from '@wagmi/core'
import { wagmiConfig } from "../_app"

interface useApproveProps {
  assetSymbol: string
}

export const useApprove = ({ assetSymbol }: useApproveProps) => {

  const asset = symbolToAsset(assetSymbol)
  const account = useAccount()
  const { writeContractAsync } = useWriteContract()

  const allowanceResult = useReadContract({
    abi: approveAndAllowanceAbi,
    address: asset?.address as `0x${string}`,
    functionName: 'allowance',
    chainId: sepolia.id,
    args: [
      account?.address as `0x${string}`,
      account?.address // here goes the spender address
    ],
  })

  const allowance = allowanceResult.data as bigint

  const approve = async (spender: string, amount: bigint) => {
    const txHash = await writeContractAsync({
      abi: approveAndAllowanceAbi,
      address: asset?.address as `0x${string}`,
      functionName: 'approve',
      chainId: sepolia.id,
      args: [
        spender,
        amount,
      ],
    })
    const receipt = getTransaction(wagmiConfig, {hash: txHash})
    return receipt
  }

  return {
    allowance,
    approve
  }
}
