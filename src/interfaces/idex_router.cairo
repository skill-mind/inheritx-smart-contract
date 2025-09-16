use starknet::ContractAddress;

#[starknet::interface]
pub trait IDEXRouter<TContractState> {
    /// @notice Swaps exact amount of input tokens for output tokens
    /// @param token_in Input token address
    /// @param token_out Output token address
    /// @param amount_in Exact amount of input tokens to swap
    /// @param amount_out_min Minimum amount of output tokens expected
    /// @param to Address to receive the output tokens
    /// @param deadline Deadline for the swap transaction
    /// @return amount_out Actual amount of output tokens received
    fn swap_exact_tokens_for_tokens(
        ref self: TContractState,
        token_in: ContractAddress,
        token_out: ContractAddress,
        amount_in: u256,
        amount_out_min: u256,
        to: ContractAddress,
        deadline: u64,
    ) -> u256;

    /// @notice Swaps exact amount of input tokens for ETH
    /// @param token_in Input token address
    /// @param amount_in Exact amount of input tokens to swap
    /// @param amount_out_min Minimum amount of ETH expected
    /// @param to Address to receive the ETH
    /// @param deadline Deadline for the swap transaction
    /// @return amount_out Actual amount of ETH received
    fn swap_exact_tokens_for_eth(
        ref self: TContractState,
        token_in: ContractAddress,
        amount_in: u256,
        amount_out_min: u256,
        to: ContractAddress,
        deadline: u64,
    ) -> u256;

    /// @notice Swaps exact amount of ETH for output tokens
    /// @param token_out Output token address
    /// @param amount_out_min Minimum amount of output tokens expected
    /// @param to Address to receive the output tokens
    /// @param deadline Deadline for the swap transaction
    /// @return amount_out Actual amount of output tokens received
    fn swap_exact_eth_for_tokens(
        ref self: TContractState,
        token_out: ContractAddress,
        amount_out_min: u256,
        to: ContractAddress,
        deadline: u64,
    ) -> u256;

    /// @notice Gets the amount of output tokens for a given input amount
    /// @param token_in Input token address
    /// @param token_out Output token address
    /// @param amount_in Amount of input tokens
    /// @return amount_out Expected amount of output tokens
    fn get_amounts_out(
        self: @TContractState,
        token_in: ContractAddress,
        token_out: ContractAddress,
        amount_in: u256,
    ) -> u256;
}
